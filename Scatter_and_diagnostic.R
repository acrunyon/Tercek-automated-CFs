# RSS_MACA_Scatter and diagnostic.R

######### INITIALS #########

# #Create output directory for MACA figs
# 
# DataFile <- list.files(path = DataDir, pattern = 'Final_Environment.RData', full.names = TRUE) # Environment needs to be added if not parsing MACA data
# load(DataFile)


#Colors for RCP 4.5, RCP 8.5
col.RCP2 = c("blue", "red")
                 
######## END INITIALS ########

##### Scatterplots for presentation ######
## Scatterplots ##
head(Future_Means)
Longx<- "annual average temperature (F)"
Longy<- "annual average precipitation (in)"
x <- "DeltaTavg"
y <- "DeltaPr"

Future_Means$PrcpIn<-Future_Means$PrcpIn
Future_Means$DeltaPr<-Future_Means$DeltaPr

# No color
dualscatter = ggplot(Future_Means, aes(DeltaTavg, DeltaPr*365, xmin=Tavg25, xmax=Tavg75, ymin=Pr25*365, ymax=Pr75*365))

dualscatter  + geom_text_repel(aes(label=GCM)) +
  geom_point(colour="black",size=4) +
  theme(axis.text=element_text(size=16),
        axis.title.x=element_text(size=16,vjust=-0.2),
        axis.title.y=element_text(size=16,vjust=0.2),
        plot.title=element_text(size=20,face="bold",vjust=2,hjust=0.5),
        legend.text=element_text(size=16), legend.title=element_text(size=16)) + 
  ###
  labs(title =paste(SiteID," Changes in climate means in ", Yr, " by GCM run",sep=""), 
       x = paste("Changes in ",Longx,sep=""), # Change
       y = paste("Changes in ",Longy,sep="")) + #change
  scale_color_manual(name="Scenarios", values=c("black")) +
  # scale_fill_manual(name="Scenarios",values = c("black")) + 
  theme(legend.position="none") +
  geom_rect(color = "black", alpha=0) + 
  geom_hline(aes(yintercept=mean(DeltaPr*365)),linetype=2) + #change
  geom_vline(aes(xintercept=mean(DeltaTavg)),linetype=2) #change

ggsave("TempVsPrcp_AllGCMs_BWscatter.png", width = 15, height = 9, path = OutDir)

####### Scatterplot with CF color
FM<-Future_Means
# '%ni%' <- Negate('%in%')
FM$CFnew<-as.character(FM$CF)
# FM$CFnew[which(FM$CFnew %ni% FutureSubset)]<-"Not Selected"
FM$CFnew[which(FM$CFnew=="Central")]<-"Not Selected"
FM$CFnew<-factor(FM$CFnew,levels=c(CFs_all[-c(3)],"Not Selected"))
levels(FM$CFnew)

ggplot(FM, aes(DeltaTavg, DeltaPr*365, xmin=Tavg25, xmax=Tavg75, ymin=Pr25*365, ymax=Pr75*365)) +
  geom_text_repel(aes(label=GCM,color=CFnew),position=position_jitter(0,.2)) + 
  geom_point(size=5,colour="black")+
  geom_point(aes(color=CFnew),size=4) +
  theme(axis.text=element_text(size=16),
        axis.title.x=element_text(size=16,vjust=-0.2),
        axis.title.y=element_text(size=16,vjust=0.2),
        plot.title=element_text(size=20,face="bold",vjust=2,hjust=0.5),
        legend.text=element_text(size=16), legend.title=element_text(size=20)) + 
  ###
  labs(title =paste0(SiteID, " Changes in climate means in ", Yr, " by GCM run"), 
       x = paste("Change in ",Longx,sep=""), # Change
       y = paste("Change in ",Longy,sep="")) + #change
  scale_color_manual(name="Climate Futures", values=colors5) +
  scale_fill_manual(name="Climate Futures",values = colors5) + 
  guides(color=guide_legend(title="Climate Futures",override.aes = list(size=7))) +
  geom_rect(color = "black", alpha=0) + 
  geom_hline(aes(yintercept=mean(DeltaPr*365)),linetype=2) + #change
  geom_vline(aes(xintercept=mean(DeltaTavg)),linetype=2)  #change

ggsave("TempVsPrcp_AllGCMs_ColorScatter.png", width = 15, height = 9, path = OutDir)
rm(FM)
#~~~~~~~~~~~~~~
# Presetation only scatterplots
#~~~~~~~~~~~~~~
# Points only w/out
dualscatter = ggplot(Future_Means, aes(DeltaTavg, DeltaPr*365, xmin=Tavg25, xmax=Tavg75, ymin=Pr25*365, ymax=Pr75*365))
dualscatter  + geom_point(colour="black",size=4) +
  theme(axis.text=element_text(size=16),
        axis.title.x=element_text(size=16,vjust=-0.5),
        axis.title.y=element_text(size=16,vjust=0.5),
        plot.title=element_text(size=20,face="bold",vjust=2,hjust=0.5),
        legend.text=element_text(size=16), legend.title=element_text(size=24)) + 
   ###
  labs(title =paste(SiteID, " Changes in climate means in ", Yr, " by GCM run\n", Longx," vs. ",Longy,sep=""), 
            x = paste("Changes in ",Longx,sep=""), # Change
            y = paste("Changes in ",Longy,sep="")) + #change
  theme(legend.position="none") +
  xlim(0, max(Future_Means$DeltaTavg))
ggsave("TempVsPrcp_AllGCMs_ScatterOnlyPoints.png", width = 15, height = 9, path = OutDir)

# Points only w/ box
dualscatter = ggplot(Future_Means, aes(DeltaTavg, DeltaPr*365, xmin=Tavg25, xmax=Tavg75, ymin=Pr25*365, ymax=Pr75*365))
dualscatter  + geom_point(colour="black",size=4) +
  theme(axis.text=element_text(size=16),
        axis.title.x=element_text(size=16,vjust=-0.5),
        axis.title.y=element_text(size=16,vjust=0.5),
        plot.title=element_text(size=20,face="bold",vjust=2,hjust=0.5),
        legend.text=element_text(size=16), legend.title=element_text(size=24)) + 
    ###
  labs(title =paste(SiteID, " Changes in climate means in ", Yr, " by GCM run\n", Longx," vs. ",Longy,sep=""), 
            x = paste("Changes in ",Longx,sep=""), # Change
            y = paste("Changes in ",Longy,sep="")) + #change
  scale_color_manual(name="Scenarios", values=c("black")) +
  # scale_fill_manual(name="Scenariow",values = c("black")) +
  theme(legend.position="none") +
  geom_rect(color = "black", alpha=0) + 
  geom_hline(aes(yintercept=mean(DeltaPr*365)),linetype=2) + #change
  geom_vline(aes(xintercept=mean(DeltaTavg)),linetype=2)  #change
ggsave("TempVsPrcp_AllGCMs_Points&Box.png", width = 15, height = 9, path = OutDir)



#######################
##########
#####
###Scatter plot showing delta precip and tavg, color by emissions scenario, with box for central CF
scatter = ggplot(Future_Means, aes(DeltaTavg, 365*DeltaPr, xmin=Tavg25, xmax=Tavg75, ymin=365*Pr25, ymax=365*Pr75))
scatter + geom_point(aes(color=emissions),size=4) + 
  PlotTheme + 
  labs(title = paste(SiteID, "- Changes in climate means in",Yr,"by GCM run"), 
            x = "Change in annual average temperature (F)", 
            y = "Change in average annual precipitation (in)") +
  scale_colour_manual(values=c("blue", "red"))+
  guides(color=guide_legend(title="Emissions\nScenarios")) +
  geom_rect(color = "blue", alpha=0) + 
  geom_hline(aes(yintercept=365*mean(DeltaPr)),linetype=2) + 
  geom_vline(aes(xintercept=mean(DeltaTavg)),linetype=2)  
#scale_y_continuous(limits=c(-3.75,3.75))

ggsave("DeltaTempVPrcp_emissions_scatter&box.png", width = 15, height = 9, path = OutDir)

###Scatter plot showing delta precip and tavg, color by emissions scenario, x-axis scaled 0-max
scatter = ggplot(Future_Means, aes(DeltaTavg, 365*DeltaPr, xmin=Tavg25, xmax=Tavg75, ymin=365*Pr25, ymax=365*Pr75))
scatter + geom_point(aes(color=emissions),size=4) + 
  PlotTheme + 
  labs(title = paste(SiteID, "- Changes in climate means in ", Yr, " by GCM run"), 
            x = "Change in annual average temperature (F)", 
            y = "Change in average annual precipitation (in)") +
  scale_colour_manual(values=col.RCP2)+
  guides(color=guide_legend(title="Emissions\nScenarios")) +
  geom_point(aes(x=mean(DeltaTavg), y=mean(365*DeltaPr)), shape=23, size=10, fill='black', colour='black') +
  scale_x_continuous(limits=c(0, max(Future_Means$DeltaTavg)+.25))

ggsave("DeltaTempVPrcp_emissions_scatter_scaled.png", width = PlotWidth, height = PlotHeight, path = OutDir)

#################################### DIAGNOSTIC CHANGE PLOTS ##############################################
#Bar graph of monthly precip/tmax/tmin by CF
ggplot(Monthly_delta, aes(x=Month,y=PrcpIn,fill=CF)) +
  geom_bar(stat="identity",position="dodge",colour="black") +
  PlotTheme +
  labs(title = paste(SiteID, "- Change in average monthly precipitation in", Yr,"vs 1979-2012"), 
       x = "Month", y = "Change in Precipitation (in)") +
  scale_fill_manual(name="Climate Future",values = colors5.2) + 
  scale_x_discrete(labels = MonthLabels)

ggsave("PrcpInDelta-Monthly-bar.png", width = 15, height = 9, path = OutDir)


#Bar graph of seasonal precip by CF
ggplot(Season_delta, aes(x=season,y=PrcpIn,fill=CF)) +
  geom_bar(stat="identity",position="dodge",colour="black") +
  PlotTheme +
  labs(title = paste(SiteID, "- Change in average seasonal precipitation in", Yr,"vs 1979-2012"), 
            x = "Season", y = "Change in Precipitation (in)") +
  scale_fill_manual(name="Climate Future",values = colors5.2)

ggsave("PrcpInDelta-Seasonal-bar.png", width = 15, height = 9, path = OutDir)


#Line plot of change in MaxTemp by CF/month
ggplot(Monthly_delta, aes(x=Month, y=TmaxF, group=CF, colour = CF)) +
  geom_line(size = 2, stat = "identity") + 
  geom_point(colour= "black", size=4, aes(fill = factor(CF), shape = factor(CF))) +
  PlotTheme +
  labs(title = paste(SiteID, "- Change in average monthly maximum temperature \nin", Yr,"vs 1979-2012"), 
            x = "Month", y = "Deg F") +
  scale_color_manual(name="Climate Future",values = colors5.2) +
  scale_fill_manual(name="Climate Future",values = colors5.2) +
  scale_shape_manual(name="Climate Future",values = c(21,22,23,24,25)) +
  scale_y_continuous(limits=c(0, ceiling(max(Monthly_delta$TmaxF)))) + 
  scale_x_discrete(labels = MonthLabels)

ggsave("TmaxFDelta-Monthly-line.png", width = 15, height = 9, path = OutDir)


####Line Plot of change in MinTemp by CF/Month
ggplot(Monthly_delta, aes(x=Month, y=TminF, group=CF, colour = CF)) +
  geom_line(size = 2, stat = "identity") + 
  geom_point(colour= "black", size=4, aes(fill = factor(CF), shape = factor(CF))) +
  PlotTheme +
  labs(title = paste(SiteID, "- Change in average monthly minimum temperature \nin", Yr,"vs 1979-2012"),
            x = "Month", y = "Deg F") +
  scale_color_manual(name="Climate Future",values = colors5.2) +
  scale_fill_manual(name="Climate Future",values = colors5.2) +
  scale_shape_manual(name="Climate Future",values = c(21,22,23,24,25)) +
  scale_y_continuous(limits=c(0, ceiling(max(Monthly_delta$TminF))))+ 
  scale_x_discrete(labels = MonthLabels)

ggsave("TminFDelta-Monthly-line.png", width = 15, height = 9, path = OutDir)


###PROGRAM COMPLETE###

