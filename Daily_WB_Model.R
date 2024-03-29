##### Water Balance Calculations 

n<-nrow(wb_sites)
WB_GCMs %>% filter(CF %in% CFs) -> WB_GCMs
T.Base = 0 

#Date format
DateFormat = "%m/%d/%Y"

#Output directory
#WBdir = file.path(FigDir,"water-balance/")# './figures/maps'
#if(dir.exists(WBdir) == FALSE){
#  dir.create(WBdir)
#}

#Select GCMs - Include RCP
unique(ALL_FUTURE$GCM)

############################################################ END USER INPUTS ###################################################################

############################################################ CREATE CLIMATE INPUTS #############################################################
### Historical
#Convert pr.In to mm and F to C
Gridmet$ppt_mm <- (Gridmet$PrcpIn*25.4)
Gridmet$tmax_C <- 5/9*(Gridmet$TmaxF - 32)
Gridmet$tmin_C <- 5/9*(Gridmet$TminF - 32)
Gridmet$tmean_C <- (Gridmet$tmax_C + Gridmet$tmin_C)/2

#### Projected
# Convert pr.In to mm
ALL_FUTURE$ppt_mm <- (ALL_FUTURE$PrcpIn*25.4)
ALL_FUTURE$tmax_C <- 5/9*(ALL_FUTURE$TmaxF - 32)
ALL_FUTURE$tmin_C <- 5/9*(ALL_FUTURE$TminF - 32)
ALL_FUTURE$tmean_C <- (ALL_FUTURE$tmax_C + ALL_FUTURE$tmin_C)/2
#Add YrMon column


#if(dir.exists(WBdir) == FALSE){
#  dir.create(WBdir)
#}

# Subset selected GCMs
ClimData <- ALL_FUTURE %>% filter(GCM %in% WB_GCMs$GCM) %>% 
  select(c("Date","ppt_mm","tmean_C","GCM")) %>%
  bind_rows(Gridmet %>% select(c("Date","ppt_mm","tmean_C","GCM")))

ClimData$GCM<-factor(ClimData$GCM,levels=unique(ClimData$GCM))

WB_GCMs <- WB_GCMs %>% 
  add_row(GCM = unique(Gridmet$GCM), CF = "Historical")
######################################################### END CLIMATE INPUTS ####################################################################


######################################################### CALCULATE WB VARIABLES ################################################################
AllDailyWB<-list()
alldaily <- list()

for (j in 1:length(levels(ClimData$GCM))){
  gcm = levels(ClimData$GCM)[j]
  DailyWB = subset(ClimData,GCM==gcm)
  for(i in 1:nrow(wb_sites)){
    ID = wb_sites$WB_site[i]
    Lat = wb_sites$Lat[i]
    Lon = wb_sites$Lon[i]
    Elev = wb_sites$Elevation[i]
    Aspect = wb_sites$Aspect[i]
    Slope = wb_sites$Slope[i]
    SWC.Max = wb_sites$SWC.Max[i]
    Wind = wb_sites$Wind[i]
    Snowpack.Init = wb_sites$Snowpack.Init[i]
    Soil.Init = wb_sites$Soil.Init[i]
    Shade.Coeff = wb_sites$Shade.Coeff[i]
    
    #Calculate daily water balance variables 
    
    DailyWB$ID = ID
    DailyWB$doy <- yday(DailyWB$Date)
    DailyWB$daylength = get_daylength(DailyWB$Date, Lat)
    DailyWB$jtemp = as.numeric(get_jtemp(Lon, Lat))
    DailyWB$F = get_freeze(DailyWB$jtemp, DailyWB$tmean_C)
    DailyWB$RAIN = get_rain(DailyWB$ppt_mm, DailyWB$F)
    DailyWB$SNOW = get_snow(DailyWB$ppt_mm, DailyWB$F)
    DailyWB$MELT = get_melt(DailyWB$tmean_C, DailyWB$jtemp, hock=4, DailyWB$SNOW, Snowpack.Init)
    DailyWB$PACK = get_snowpack(DailyWB$jtemp, DailyWB$SNOW, DailyWB$MELT)
    DailyWB$W = DailyWB$MELT + DailyWB$RAIN
    if(PET_Method == "Hamon"){
      DailyWB$PET = ET_Hamon_daily(DailyWB)
    } else {
      if(PET_Method == "Penman-Monteith"){
        DailyWB$PET = ET_PenmanMonteith_daily(DailyWB)
      } else {
        if(PET_Method == "Oudin"){
          DailyWB$PET = get_OudinPET(DailyWB$doy, Lat, DailyWB$PACK, DailyWB$tmean_C, Slope, Aspect, Shade.Coeff)
        } else {
          print("Error - PET method not found")
        }
      }
    }
    DailyWB$PET = modify_PET(DailyWB$PET, Slope, Aspect, Lat, Shade.Coeff)
    DailyWB$W_PET = DailyWB$W - DailyWB$PET
    DailyWB$SOIL = get_soil(DailyWB$W, Soil.Init, DailyWB$PET, DailyWB$W_PET, SWC.Max)
    DailyWB$DSOIL = diff(c(Soil.Init, DailyWB$SOIL))
    DailyWB$AET = get_AET(DailyWB$W, DailyWB$PET, DailyWB$SOIL, Soil.Init)
    DailyWB$W_ET_DSOIL = DailyWB$W - DailyWB$AET - DailyWB$DSOIL
    DailyWB$D = DailyWB$PET - DailyWB$AET
    DailyWB$GDD = get_GDD(DailyWB$tmean_C, T.Base)
    alldaily[[i]] = DailyWB
  }
  
  AllDailyWB[[j]] = do.call(rbind,alldaily)
}

WBData<-do.call(rbind,AllDailyWB)
rm(ClimData)
######################################################### END WB VARIABLE CALCULATIONS ################################################################

######################################################### AGGREGATE OUTPUTS TO MONTLY/ANNUAL ################################################################
WBData <- subset(WBData, GCM %in% WB_GCMs$GCM | GCM == "gridmet.historical")

WBData$yrmon = strftime(WBData$Date, "%Y%m")
WBData$year = strftime(WBData$Date, "%Y")

#Monthly
MonthlyWB = aggregate(ppt_mm~yrmon+GCM,data=aggregate(ppt_mm~yrmon+GCM+ID,data=WBData,sum),mean)
colnames(MonthlyWB)[3]<-"sum_p.mm"

MonthlyWB$avg_t.C = aggregate(tmean_C ~ yrmon+GCM, data=WBData, FUN=mean)[,3]
MonthlyWB$sum_rain.mm = aggregate(RAIN~yrmon+GCM,data=aggregate(RAIN~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$sum_snow.mm = aggregate(SNOW~yrmon+GCM,data=aggregate(SNOW~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$max_pack.mm = aggregate(PACK~yrmon+GCM,data=aggregate(PACK~yrmon+GCM+ID,data=WBData,max),mean)[,3]
MonthlyWB$sum_melt.mm = aggregate(MELT~yrmon+GCM,data=aggregate(MELT~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$sum_w.mm = aggregate(W~yrmon+GCM,data=aggregate(W~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$sum_pet.mm = aggregate(PET~yrmon+GCM,data=aggregate(PET~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$sum_w_pet.mm = aggregate(W_PET~yrmon+GCM,data=aggregate(W_PET~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$avg_soil.mm = aggregate(SOIL ~ yrmon+GCM, data=WBData, FUN=mean)[,3]
MonthlyWB$sum_aet.mm = aggregate(AET~yrmon+GCM,data=aggregate(AET~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$runoff.mm = aggregate(W_ET_DSOIL~yrmon+GCM,data=aggregate(W_ET_DSOIL~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$sum_d.mm = aggregate(D~yrmon+GCM,data=aggregate(D~yrmon+GCM+ID,data=WBData,sum),mean)[,3]
MonthlyWB$sum_gdd.mm = aggregate(GDD~yrmon+GCM,data=aggregate(GDD~yrmon+GCM+ID,data=WBData,sum),mean)[,3]

#Annual
AnnualWB = aggregate(ppt_mm ~ year+GCM, data=aggregate(ppt_mm~year+GCM+ID,data=WBData,sum), mean)
colnames(AnnualWB)[3]<-"sum_p.mm"

AnnualWB$avg_t.C = aggregate(tmean_C ~ year+GCM, data=WBData, FUN=mean)[,3]
AnnualWB$sum_rain.mm = aggregate(RAIN ~ year+GCM, data=aggregate(RAIN~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$sum_snow.mm = aggregate(SNOW ~ year+GCM, data=aggregate(SNOW~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$max_pack.mm = aggregate(PACK ~ year+GCM, data=aggregate(PACK~year+GCM+ID,data=WBData,max), mean)[,3]
AnnualWB$sum_melt.mm = aggregate(MELT ~ year+GCM, data=aggregate(MELT~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$sum_w.mm = aggregate(W ~ year+GCM, data=aggregate(W~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$sum_pet.mm = aggregate(PET ~ year+GCM, data=aggregate(PET~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$sum_w_pet.mm = aggregate(W_PET ~ year+GCM, data=aggregate(W_PET~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$avg_soil.mm = aggregate(SOIL ~ year+GCM, data=WBData, FUN=mean)[,3]
AnnualWB$sum_aet.mm = aggregate(AET ~ year+GCM, data=aggregate(AET~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$runoff.mm = aggregate(W_ET_DSOIL ~ year+GCM, data=aggregate(W_ET_DSOIL~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$sum_d.mm = aggregate(D ~ year+GCM, data=aggregate(D~year+GCM+ID,data=WBData,sum), mean)[,3]
AnnualWB$sum_gdd.C = aggregate(GDD ~ year+GCM, data=aggregate(GDD~year+GCM+ID,data=WBData,sum), mean)[,3]

MonthlyWB %>% mutate(across(3:length(MonthlyWB), round, 1)) %>% write.csv(.,paste0(TableDir,"WB-Monthly.csv"),row.names=FALSE)
AnnualWB %>% mutate(across(3:length(AnnualWB), round, 1)) %>% write.csv(.,paste0(TableDir,"WB-Annual.csv"),row.names=FALSE)

#######################################################################################################################
######################################### PLOTTING ####################################################################
# Inputs
MonthlyWB <- MonthlyWB %>% mutate(Date = as.POSIXct(paste(substr(yrmon,1,4),substr(yrmon,5,6),"1",sep="-"),format="%Y-%m-%d"),
                                  year = format(Date, "%Y"))
MonthlyWB <- subset(MonthlyWB, year >= Yr-Range/2 & year <= Yr+Range/2 | year <= 2012)
AnnualWB <- subset(AnnualWB, year >= Yr-Range/2 & year <= Yr+Range/2 | year <= 2012)
MonthlyWB<-merge(MonthlyWB,WB_GCMs,by="GCM", all.x=T)
MonthlyWB$CF<-factor(MonthlyWB$CF, levels=c("Historical",CFs))
MonthlyWB <- MonthlyWB %>%  drop_na()

AnnualWB<-merge(AnnualWB,WB_GCMs,by="GCM", all.x=T)
AnnualWB$CF<-factor(AnnualWB$CF, levels=c("Historical",CFs))
AnnualWB <- AnnualWB %>% drop_na()

# Conversions to Imperial Units

#Annual Conversions
AnnualWB_in <- AnnualWB %>% mutate(sum_snow.in = sum_snow.mm/ 25.4,
                     max_pack.in = max_pack.mm/ 25.4,
                     sum_pet.in = sum_pet.mm/ 25.4,
                     avg_soil.in=avg_soil.mm/ 25.4,
                     sum_aet.in = sum_aet.mm/ 25.4,
                     runoff.in = runoff.mm/ 25.4,
                     sum_d.in = sum_d.mm/ 25.4) 

#Monthly Conversions
MonthlyWB_in <- MonthlyWB %>% mutate(sum_snow.in = sum_snow.mm/ 25.4,
                     max_pack.in = max_pack.mm/ 25.4,
                     sum_pet.in = sum_pet.mm/ 25.4,
                     avg_soil.in=avg_soil.mm/ 25.4,
                     sum_aet.in = sum_aet.mm/ 25.4,
                     runoff.in = runoff.mm/ 25.4,
                     sum_d.in = sum_d.mm/ 25.4,
                     sum_p.in = sum_p.mm/ 25.4) %>% 
  mutate(Month = substr(MonthlyWB$yrmon, 5, 7)) %>% group_by(CF, Month) %>% 
  summarise_at(vars(sum_snow.in,max_pack.in,sum_pet.in,avg_soil.in,sum_aet.in, runoff.in,sum_d.in,sum_p.in),mean) 

MonthlyWB_H <- subset(MonthlyWB_in, CF == "Historical")
MonthlyWB_delta = list()
split<-split(MonthlyWB_in,MonthlyWB_in$CF)
for(i in 1:length(split)){
  MD <- split[[i]]
  MD[,3:length(MD)] <- MD[,3:length(MD)] - MonthlyWB_H[,3:length(MonthlyWB_H)]
  MonthlyWB_delta[[i]] <- MD ; rm(MD)
}
MonthlyWB_delta<- ldply(MonthlyWB_delta, data.frame)
MonthlyWB_delta <- subset(MonthlyWB_delta, CF %in% CFs)
MonthlyWB_delta$CF<-droplevels(MonthlyWB_delta$CF)


ggplot(AnnualWB_in, aes(x=sum_d.in, y=sum_aet.in, colour=CF)) +  
  geom_point(size=3) +   
  geom_smooth(method="lm", se=FALSE, size=2) +
  scale_colour_manual("",values=col) +
  labs(
    y = "Annual Actual Evapotranspiration (in)",
    x = "Annual water deficit (in)",
    colour = "GCM",
        title = paste("Water Balance for ",SiteID,sep=""),caption=
      if(MethodCaption == "Y"){"I"}) + PlotTheme + theme(axis.title.x=element_text(size=18, vjust=0.5,  margin=margin(t=20, r=20, b=20, l=20))) 
  # annotate(geom="text", x=Inf, y=-Inf, label="I",color="black",vjust=-1,hjust=1)

ggsave("WaterBalance.png", path = FigDir, width = PlotWidth, height = PlotHeight)

density_plot(AnnualWB_in, xvar=sum_d.in,cols=col,title=paste(SiteID," Water Deficit for GCMs \nin", Yr,  "and Historical Period (", BasePeriod,")",sep=" "),
             xlab="Annual deficit (in)",CFmethod="I")
ggsave("sum_d.in-Density.png", path = FigDir, width = PlotWidth, height = PlotHeight)

density_plot(AnnualWB_in, xvar=avg_soil.in,cols=col,title=paste(SiteID," Soil Moisture for GCMs \nin", Yr,  "and Historical Period (", BasePeriod,")",sep=" "),
             xlab="Annual soil moisture (in)",CFmethod="I")
ggsave("avg_SM.in-Density.png", path = FigDir, width = PlotWidth, height = PlotHeight)


### Monthly Plots
WBMonthlyLong <- MonthlyWB_in %>% select(.,-c("sum_snow.in","max_pack.in","avg_soil.in","sum_d.in","runoff.in")) %>% 
  rename(PET=sum_pet.in, AET=sum_aet.in, Ppt=sum_p.in) %>% 
  gather(Variable, water, -c(CF, Month)) 
WBMonthlyLong$Variable <- factor(WBMonthlyLong$Variable,levels = c("Ppt","PET","AET"))

WBplot <- function(scenario, cols){
ggplot(MonthlyWB_in %>% filter(CF==scenario)) +
  geom_ribbon(aes(Month, ymin = sum_pet.in, ymax=sum_p.in,fill="Surplus/Runoff",group="CF"),linetype = 0, alpha=1) +
  geom_ribbon(aes(Month, ymin = sum_aet.in, ymax=sum_pet.in,fill="Deficit",group="CF"),linetype = 0,alpha=1) +
  geom_ribbon(aes(Month, ymin = 0, ymax=sum_aet.in,fill="Utilization",group="CF"),linetype = 0,alpha=1) +
  geom_line(data = WBMonthlyLong %>% filter(CF == scenario), aes(x=Month, y = water, group=Variable, linetype = Variable), size = 1.5, stat = "identity",colour="black") +
  scale_fill_manual("",
                    values=c('Surplus/Runoff'="cornflowerblue",'Utilization'="palegreen3",'Deficit'="brown1")) +
  scale_linetype_manual(values=c("solid","twodash", "dotted")) +
  labs(title = scenario) + PlotTheme + 
  theme(axis.title.x=element_blank(),axis.title.y=element_blank(),
        plot.background = element_rect(colour = cols, fill=NA, size=5)) +
  scale_x_discrete(labels = MonthLabels) +
    coord_cartesian(ylim = c(0, max(MonthlyWB_in[,c(5,7:10)]))) }

Hist.WBplot <- WBplot(scenario="Historical",cols="grey")
CF1.WBplot <- WBplot(scenario=CFs[1],cols=colors2[1])
CF2.WBplot <- WBplot(scenario=CFs[2],cols=colors2[2])

Hist.WBplot <- Hist.WBplot + theme(legend.title=element_text(size=12),legend.text=element_text(size=14),legend.position = "bottom", legend.spacing.x = unit(0.5, 'cm'),legend.key.width = unit(1.75, 'cm'))
CF1.WBplot <- CF1.WBplot + theme(legend.title=element_text(size=12),legend.text=element_text(size=14),legend.position = "bottom", legend.spacing.x = unit(0.5, 'cm'),legend.key.width = unit(1.75, 'cm'))
CF2.WBplot <- CF2.WBplot + theme(legend.title=element_text(size=12),legend.text=element_text(size=14),legend.position = "bottom", legend.spacing.x = unit(0.5, 'cm'),legend.key.width = unit(1.75, 'cm'))


WBgrid <- ggarrange(Hist.WBplot, CF1.WBplot, CF2.WBplot, ncol = 1, nrow = 3,common.legend = T)
annotate_figure(WBgrid, left = textGrob("Water (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = (textGrob("Month", gp = gpar(cex = 1.3))),
                top = textGrob(paste0(SiteID, " monthly water balance in ", Yr),
                               gp=gpar(fontface="bold", col="black",  fontsize=22)),
                fig.lab = "I",
                fig.lab.pos = "bottom.right")
ggsave("WaterBalance_Monthly_Vertical.jpg", width = 15, height = 9, path = FigDir,bg="white")


WBgrid <- ggarrange(Hist.WBplot, CF1.WBplot, CF2.WBplot, ncol = 3, nrow = 1,common.legend = T)
annotate_figure(WBgrid, left = textGrob("Water (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("Month", gp = gpar(cex = 1.3)),
                top = textGrob(paste0(SiteID, " monthly water balance in ", Yr),
                               gp=gpar(fontface="bold", col="black",  fontsize=22)),
                fig.lab = "I",
                fig.lab.pos = "bottom.right")
ggsave("WaterBalance_Monthly_Horizontal.jpg", width = 15, height = 9, path = FigDir, bg="white")
rm(Hist.WBplot, CF1.WBplot,CF2.WBplot,WBgrid)


## avg_SM.in
Month_line_plot(MonthlyWB_delta, Month, avg_soil.in, grp=CF, cols=colors2, 
                title= paste(SiteID, " Change in average monthly soil moisture \nin", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in soil moisture (inches)",CFmethod="I") 
ggsave("avg_SM.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight)

## sum_d.in
Month_line_plot(MonthlyWB_delta, Month, sum_d.in, grp=CF, cols=colors2, 
                title= paste(SiteID, " Change in average monthly water deficit \nin", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in deficit (inches)",CFmethod="I")
ggsave("sum_d.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight)

## runoff.in
Month_line_plot(MonthlyWB_delta, Month, runoff.in, grp=CF, cols=colors2, 
                title= paste(SiteID, " Change in average monthly surplus/runoff \nin", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in surplus/runoff (inches)",CFmethod="I")
ggsave("sum_runoff.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight)

## max_pack.in
Month_line_plot(MonthlyWB_delta, Month, max_pack.in, grp=CF, cols=colors2, 
                title= paste(SiteID, " Change in average monthly SWE \nin", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in SWE (inches)",CFmethod="I")
ggsave("sum_SWEaccum.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight)

## sum_aet.in
Month_line_plot(MonthlyWB_delta, Month, sum_aet.in, grp=CF, cols=colors2, 
                title= paste(SiteID, " Change in average monthly AET \nin", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in AET (inches)",CFmethod="I")
ggsave("sum_aet.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight)


### Additional plots
# Max SWE
AnnualWB_in <- rename(AnnualWB_in, Year=year)
# AnnualWB$max_SWEaccum.in <- aggregate(SWEaccum.in ~ Year+GCM, data=aggregate(SWEaccum.in~Year+GCM,data=WBData,sum), mean)[,3]
density_plot(AnnualWB_in, xvar=max_pack.in,cols=col,title=paste(SiteID," maximum annual SWE \nin", Yr,  "and Historical Period (", BasePeriod,")",sep=" "),
             xlab="Max SWE (in)",CFmethod="I")
ggsave("SWEaccum.in-Density-max.png", path = FigDir, width = PlotWidth, height = PlotHeight)

var_bar_plot(AnnualWB_in, "max_pack.in", cols=colors3, ylab="Max SWE (in)",
             title=paste0(SiteID, " Average annual max SWE in ", Yr, " vs ", BasePeriod),CFmethod="I")
ggsave("max_pack.in-Annual-bar.png", width = PlotWidth, height = PlotHeight, path = FigDir)

var_line_plot(AnnualWB_in, var=max_pack.in, cols=col, title=paste0(SiteID, " Average annual max SWE in ", Yr, " vs ", BasePeriod),
              ylab="Max SWE (in)",CFmethod="I")
ggsave("max_SWEaccum.in-Annual-line.png", width = PlotWidth, height = PlotHeight, path = FigDir)


### Adjust water year for spaghetti plots
hydro.day.new = function(x, start.month = 10L){
  x <- as.Date(x)
  start.yr = year(x) - (month(x) < start.month)
  start.date = make_date(start.yr, start.month, 1L)
  as.integer(x - start.date + 1L)
}
WBData$WaterYr <- hydro.day.new(WBData$Date)

## Add CFs to WBData

WBData <- WBData %>% drop_na %>% rename(Year=year) %>% mutate(
  PACK.in=PACK/ 25.4,
  Runoff.in=W_ET_DSOIL /25.4,
  AET.in = AET / 25.4, 
  SOIL.in = SOIL / 25.4) %>% left_join(WB_GCMs,by="GCM")

# SWE spaghetti
Hist.SWE<-spaghetti_plot_wateryr(subset(WBData,CF=="Historical"),"PACK.in",col=col[1],CF="Historical")
CF1.SWE<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[1]),"PACK.in",col=col[2], CF=CFs[1])
CF2.SWE<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[2]),"PACK.in",col=col[3], CF=CFs[2])

SWEgrid <- ggarrange(Hist.SWE, CF1.SWE, CF2.SWE, ncol = 1, nrow = 3,common.legend = T)

annotate_figure(SWEgrid, left = textGrob("SWE (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("Water year day", gp = gpar(cex = 1.3)),
                top = textGrob(paste0(SiteID, " Daily SWE for each climate future by water year"),
                                gp=gpar(fontface="bold", col="black",  fontsize=22)),
                fig.lab=if(MethodCaption == "Y"){"I"},fig.lab.pos = "bottom.right")
ggsave("SWEaccum.in-spaghetti.jpg", width = 15, height = 9, path = FigDir, bg="white")


# runoff spaghetti
Hist.runoff<-spaghetti_plot_wateryr(subset(WBData,CF=="Historical"),"Runoff.in",col=col[1],CF="Historical")
CF1.runoff<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[1]),"Runoff.in",col=col[2], CF=CFs[1])
CF2.runoff<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[2]),"Runoff.in",col=col[3], CF=CFs[2])

runoffgrid <- ggarrange(Hist.runoff, CF1.runoff, CF2.runoff, ncol = 1, nrow = 3,common.legend = T)

annotate_figure(runoffgrid, left = textGrob("Surplus/Runoff (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("Water year day", gp = gpar(cex = 1.3)),
                top = textGrob(paste0(SiteID, " Daily surplus/runoff for each climate future by water year"),
                               gp=gpar(fontface="bold", col="black",  fontsize=22)),
                fig.lab=if(MethodCaption == "Y"){"I"},fig.lab.pos = "bottom.right")
ggsave("Runoff.in-spaghetti.jpg", width = 15, height = 9, path = FigDir, bg="white")

# aet spaghetti
Hist.AET<-spaghetti_plot_wateryr(subset(WBData,CF=="Historical"),"AET.in",col=col[1],CF="Historical")
CF1.AET<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[1]),"AET.in",col=col[2], CF=CFs[1])
CF2.AET<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[2]),"AET.in",col=col[3], CF=CFs[2])

aetgrid <- ggarrange(Hist.AET, CF1.AET, CF2.AET, ncol = 1, nrow = 3,common.legend = T)

annotate_figure(aetgrid, left = textGrob("AET (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("Water year day", gp = gpar(cex = 1.3)),
                top = textGrob(paste0(SiteID, " Daily AET for each climate future by water year"),
                               gp=gpar(fontface="bold", col="black",  fontsize=22)),
                fig.lab=if(MethodCaption == "Y"){"I"},fig.lab.pos = "bottom.right")
ggsave("AET.in-spaghetti.jpg", width = 15, height = 9, path = FigDir, bg="white")


# SoilMoisture spaghetti
Hist.SM<-spaghetti_plot_wateryr(subset(WBData,CF=="Historical"),"SOIL.in",col=col[1],CF="Historical")
CF1.SM<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[1]),"SOIL.in",col=col[2], CF=CFs[1])
CF2.SM<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[2]),"SOIL.in",col=col[3], CF=CFs[2])

SMgrid <- ggarrange(Hist.SM, CF1.SM, CF2.SM, ncol = 1, nrow = 3,common.legend = T)

annotate_figure(SMgrid, left = textGrob("Soil Moisture (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("Water year day", gp = gpar(cex = 1.3)),
                top = textGrob(paste0(SiteID, " Daily Soil Moisture for each climate future by water year"),
                               gp=gpar(fontface="bold", col="black",  fontsize=22)),
                fig.lab=if(MethodCaption == "Y"){"I"},fig.lab.pos = "bottom.right")
ggsave("SM.in-spaghetti.jpg", width = 15, height = 9, path = FigDir, bg="white")


rm(Hist.SWE,CF1.SWE,CF2.SWE,SWEgrid,Hist.runoff,CF1.runoff,CF2.runoff, runoffgrid,Hist.AET,CF1.AET,CF2.AET,aetgrid,Hist.SM,
   CF1.SM,CF2.SM,SMgrid)
gc()






