WBData <- subset(WBdat, GCM %in% WB_GCMs$GCM | GCM == "gridmet.historical")
WBData <- subset(WBData, Year >= Yr-Range/2 & Year <= Yr+Range/2 | Year <= 2012)

######################################################### AGGREGATE OUTPUTS TO MONTLY/ANNUAL ################################################################

WBData$yrmon = strftime(WBData$Date, "%Y%m")

#Monthly
MonthlyWB = aggregate(Rain.in~yrmon+GCM,data=aggregate(Rain.in~yrmon+GCM,data=WBData,sum),mean)
colnames(MonthlyWB)[3]<-"sum_rain.in"

MonthlyWB$max_SWEaccum.in = aggregate(SWEaccum.in~yrmon+GCM,data=WBData,max)[,3]
MonthlyWB$sum_runoff.in = aggregate(Runoff.in~yrmon+GCM,data=aggregate(Runoff.in~yrmon+GCM,data=WBData,sum),mean)[,3]
MonthlyWB$sum_pet.in = aggregate(PET.in~yrmon+GCM,data=aggregate(PET.in~yrmon+GCM,data=WBData,sum),mean)[,3]
MonthlyWB$avg_SM.in = aggregate(SM.in ~ yrmon+GCM, data=WBData, FUN=mean)[,3]
MonthlyWB$sum_aet.in = aggregate(AET.in~yrmon+GCM,data=aggregate(AET.in~yrmon+GCM,data=WBData,sum),mean)[,3]
MonthlyWB$sum_d.in = aggregate(D.in~yrmon+GCM,data=aggregate(D.in~yrmon+GCM,data=WBData,sum),mean)[,3]

#Annual
AnnualWB = aggregate(Rain.in ~ Year+GCM, data=aggregate(Rain.in~Year+GCM,data=WBData,sum), mean)
colnames(AnnualWB)[3]<-"sum_rain.in"

AnnualWB$max_SWEaccum.in = aggregate(SWEaccum.in ~ Year+GCM, data=WBData, max)[,3]
AnnualWB$sum_runoff.in = aggregate(Runoff.in ~ Year+GCM, data=aggregate(Runoff.in~Year+GCM,data=WBData,sum), mean)[,3]
AnnualWB$sum_pet.in = aggregate(PET.in ~ Year+GCM, data=aggregate(PET.in~Year+GCM,data=WBData,sum), mean)[,3]
AnnualWB$avg_SM.in = aggregate(SM.in ~ Year+GCM, data=WBData, FUN=mean)[,3]
AnnualWB$sum_aet.in = aggregate(AET.in ~ Year+GCM, data=aggregate(AET.in~Year+GCM,data=WBData,sum), mean)[,3]
AnnualWB$sum_d.in = aggregate(D.in ~ Year+GCM, data=aggregate(D.in~Year+GCM,data=WBData,sum), mean)[,3]

MonthlyWB %>% mutate_at(3:9,funs(round(.,1))) %>% write.csv(.,paste0(TableDir,"WB-Monthly.csv"),row.names=FALSE)
AnnualWB %>% mutate_at(3:9,funs(round(.,1))) %>% write.csv(.,paste0(TableDir,"WB-Annual.csv"),row.names=FALSE)


#######################################################################################################################
######################################### PLOTTING ####################################################################
# Inputs
MonthlyWB<-merge(MonthlyWB,WB_GCMs,by="GCM", all.x=T)
MonthlyWB$CF<-factor(MonthlyWB$CF, levels=c("Historical",CFs))
MonthlyWB$CF[is.na(MonthlyWB$CF)] <- "Historical"
AnnualWB<-merge(AnnualWB,WB_GCMs,by="GCM", all.x=T)
AnnualWB$CF<-factor(AnnualWB$CF, levels=c("Historical",CFs))
AnnualWB$CF[is.na(AnnualWB$CF)] <- "Historical"


ggplot(AnnualWB, aes(x=sum_d.in, y=sum_aet.in, colour=CF)) +  
  geom_point(size=3) +   
  geom_smooth(method="lm", se=FALSE, size=2) +
  scale_colour_manual("",values=col) +
  labs(
    y = "Annual Actual Evapotranspiration (in)",
    x = "Annual water deficit (in)",
    colour = "GCM",
    title = paste("Water Balance for ",SiteID,sep="")  
  ) + PlotTheme + theme(axis.title.x=element_text(size=22, vjust=0.5,  margin=margin(t=20, r=20, b=20, l=20)))

ggsave("WaterBalance.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

density_plot(AnnualWB, xvar=sum_d.in,cols=col,title=paste(SiteID,"Water Deficit for GCMs in", Yr,  "and Historical Period (", BasePeriod,")",sep=" "),
             xlab="Annual deficit (in)")
ggsave("sum_d.in-Density.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

density_plot(AnnualWB, xvar=avg_SM.in,cols=col,title=paste(SiteID,"Soil Moisture for GCMs in", Yr,  "and Historical Period (", BasePeriod,")",sep=" "),
             xlab="Annual soil moisture (in)")
ggsave("avg_SM.in-Density.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")


### Monthly Plots
MonthlyWB$Month <- substr(MonthlyWB$yrmon, 5, 7)
MonthlyWB_mean <- aggregate(.~CF+Month, MonthlyWB[,3:11],mean)
MonthlyWB_H <- subset(MonthlyWB_mean, CF == "Historical")
MonthlyWB_delta = list()
split<-split(MonthlyWB_mean,MonthlyWB_mean$CF)
for(i in 1:length(split)){
  MD <- split[[i]]
  MD[,3:9] <- MD[,3:9] - MonthlyWB_H[,3:9]
  MonthlyWB_delta[[i]] <- MD ; rm(MD)
}
MonthlyWB_delta<- ldply(MonthlyWB_delta, data.frame)
MonthlyWB_delta <- subset(MonthlyWB_delta, CF %in% CFs)
MonthlyWB_delta$CF<-droplevels(MonthlyWB_delta$CF)


## avg_SM.in
Month_line_plot(MonthlyWB_delta, Month, avg_SM.in, grp=CF, cols=colors2, 
                title= paste("Change in average monthly soil moisture in", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in soil moisture (inches)")
ggsave("avg_SM.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

dot_plot(MonthlyWB_delta, avg_SM.in, Month, grp=CF, cols=colors2,
         title = paste("Change in average monthly soil moisture in", Yr, "vs Historical (",BasePeriod,")"),
         xlab="Change in soil moisture (inches)",ylab="Month",labels=MonthLabels)
ggsave("avg_SM.in-Monthly-dot.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

## sum_d.in
Month_line_plot(MonthlyWB_delta, Month, sum_d.in, grp=CF, cols=colors2, 
                title= paste("Change in average monthly water deficit in", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in deficit (inches)")
ggsave("sum_d.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

dot_plot(MonthlyWB_delta, sum_d.in, Month, grp=CF, cols=colors2,
         title = paste("Change in average monthly water deficit in", Yr, "vs Historical (",BasePeriod,")"),
         xlab="Change in deficit (inches)",ylab="Month",labels=MonthLabels)
ggsave("sum_d.in-Monthly-dot.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")


## sum_runoff.in
Month_line_plot(MonthlyWB_delta, Month, sum_runoff.in, grp=CF, cols=colors2, 
                title= paste("Change in average monthly runoff in", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in runoff (inches)")
ggsave("sum_runoff.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

dot_plot(MonthlyWB_delta, sum_runoff.in, Month, grp=CF, cols=colors2,
         title = paste("Change in average monthly runoff in", Yr, "vs Historical (",BasePeriod,")"),
         xlab="Change in runoff (inches)",ylab="Month",labels=MonthLabels)
ggsave("sum_runoff.in-Monthly-dot.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")


## sum_SWEaccum.in
Month_line_plot(MonthlyWB_delta, Month, max_SWEaccum.in, grp=CF, cols=colors2, 
                title= paste("Change in average monthly SWE in", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in SWE (inches)")
ggsave("sum_SWEaccum.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

dot_plot(MonthlyWB_delta, max_SWEaccum.in, Month, grp=CF, cols=colors2,
         title = paste("Change in average monthly SWE in", Yr, "vs Historical (",BasePeriod,")"),
         xlab="Change in SWE (inches)",ylab="Month",labels=MonthLabels)
ggsave("sum_SWEaccum.in-Monthly-dot.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")


## sum_aet.in
Month_line_plot(MonthlyWB_delta, Month, sum_aet.in, grp=CF, cols=colors2, 
                title= paste("Change in average monthly AET in", Yr, "vs Historical (",BasePeriod,")"),
                xlab="Month", ylab="Change in AET (inches)")
ggsave("sum_aet.in-Monthly-line.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

dot_plot(MonthlyWB_delta, sum_aet.in, Month, grp=CF, cols=colors2,
         title = paste("Change in average monthly AET in", Yr, "vs Historical (",BasePeriod,")"),
         xlab="Change in AET (inches)",ylab="Month",labels=MonthLabels)
ggsave("sum_aet.in-Monthly-dot.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")


### Additional plots
# Max SWE
# AnnualWB$max_SWEaccum.in <- aggregate(SWEaccum.in ~ Year+GCM, data=aggregate(SWEaccum.in~Year+GCM,data=WBData,sum), mean)[,3]
density_plot(AnnualWB, xvar=max_SWEaccum.in,cols=col,title=paste(SiteID,"maximum annual SWE in", Yr,  "and Historical Period (", BasePeriod,")",sep=" "),
             xlab="Max SWE (in)")
ggsave("SWEaccum.in-Density-max.png", path = FigDir, width = PlotWidth, height = PlotHeight, bg="white")

var_bar_plot(AnnualWB, "max_SWEaccum.in", cols=colors3, ylab="Max SWE (in)",
             title=paste0("Average annual max SWE in ", Yr, " vs ", BasePeriod))
ggsave("max_SWEaccum.in-Annual-bar.png", width = PlotWidth, height = PlotHeight, path = FigDir, bg="white")

var_line_plot(AnnualWB, var=max_SWEaccum.in, cols=col, title="Average annual max SWE in.",
              ylab="Max SWE (in)")
ggsave("max_SWEaccum.in-Annual-line.png", width = PlotWidth, height = PlotHeight, path = FigDir, bg="white")


### Adjust water year for spaghetti plots
hydro.day.new = function(x, start.month = 10L){
  x <- as.Date(x)
  start.yr = year(x) - (month(x) < start.month)
  start.date = make_date(start.yr, start.month, 1L)
  as.integer(x - start.date + 1L)
}
WBData$WaterYr <- hydro.day.new(WBData$Date)

# SWE spaghetti
Hist.SWE<-spaghetti_plot_wateryr(subset(WBData,CF=="Historical"),"SWEaccum.in",col=col[1],CF="Historical")
CF1.SWE<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[1]),"SWEaccum.in",col=col[2], CF=CFs[1])
CF2.SWE<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[2]),"SWEaccum.in",col=col[3], CF=CFs[2])

SWEgrid <- ggarrange(Hist.SWE, CF1.SWE, CF2.SWE, ncol = 1, nrow = 3,common.legend = T)

annotate_figure(SWEgrid, left = textGrob("SWE (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                         bottom = textGrob("Water year day", gp = gpar(cex = 1.3)),
                         top = textGrob("Daily SWE for each climate future by water year",
                                        gp=gpar(fontface="bold", col="black",  fontsize=22)))
ggsave("SWEaccum.in-spaghetti.png", width = PlotWidth, height = PlotHeight, path = FigDir, bg="white")


# runoff spaghetti


Hist.runoff<-spaghetti_plot_wateryr(subset(WBData,CF=="Historical"),"Runoff.in",col=col[1],CF="Historical")
CF1.runoff<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[1]),"Runoff.in",col=col[2], CF=CFs[1])
CF2.runoff<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[2]),"Runoff.in",col=col[3], CF=CFs[2])

runoffgrid <- ggarrange(Hist.runoff, CF1.runoff, CF2.runoff, ncol = 1, nrow = 3,common.legend = T)

annotate_figure(runoffgrid, left = textGrob("Runoff (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("Water year day", gp = gpar(cex = 1.3)),
                top = textGrob("Daily Runoff for each climate futureby water year",
                               gp=gpar(fontface="bold", col="black",  fontsize=22)))
ggsave("Runoff.in-spaghetti.png", width = PlotWidth, height = PlotHeight, path = FigDir, bg="white")

rm(Hist.SWE,CF1.SWE,CF2.SWE,SWEgrid,Hist.runoff,CF1.runoff,CF2.runoff, runoffgrid)

# aet spaghetti


Hist.AET<-spaghetti_plot_wateryr(subset(WBData,CF=="Historical"),"AET.in",col=col[1],CF="Historical")
CF1.AET<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[1]),"AET.in",col=col[2], CF=CFs[1])
CF2.AET<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[2]),"AET.in",col=col[3], CF=CFs[2])

aetgrid <- ggarrange(Hist.AET, CF1.AET, CF2.AET, ncol = 1, nrow = 3,common.legend = T) + theme(plot.margin = margin(1,1,1,1, "in")) 

annotate_figure(aetgrid, left = textGrob("AET (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("Water year day", gp = gpar(cex = 1.3)),
                top = textGrob("Daily AET for each climate future by water year",
                               gp=gpar(fontface="bold", col="black",  fontsize=18)))
ggsave("AET.in-spaghetti.png", width = 14, height = 11, path = FigDir, bg="white", dpi=150)


# SoilMoisture spaghetti


Hist.SM<-spaghetti_plot_wateryr(subset(WBData,CF=="Historical"),"SM.in",col=col[1],CF="Historical")
CF1.SM<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[1]),"SM.in",col=col[2], CF=CFs[1])
CF2.SM<-spaghetti_plot_wateryr(subset(WBData,CF %in% CFs[2]),"SM.in",col=col[3], CF=CFs[2])

SMgrid <- ggarrange(Hist.SM, CF1.SM, CF2.SM, ncol = 1, nrow = 3,common.legend = T)

annotate_figure(aetgrid, left = textGrob("Soil Moisture (in)", rot = 90, vjust = 1, gp = gpar(cex = 1.3)),
                bottom = textGrob("Water year day", gp = gpar(cex = 1.3)),
                top = textGrob("Daily Soil Moisture for each climate future by water year",
                               gp=gpar(fontface="bold", col="black",  fontsize=22)))
ggsave("SM.in-spaghetti.png", width = 12, height = 9, path = FigDir, bg="white")


rm(Hist.SWE,CF1.SWE,CF2.SWE,SWEgrid,Hist.runoff,CF1.runoff,CF2.runoff, runoffgrid,Hist.AET,CF1.AET,CF2.AET,aetgrid,Hist.SM,
   CF1.SM,CF2.SM,SMgrid)

