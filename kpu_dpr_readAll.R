library(dplyr)

setwd('C:\\Users\\ghilmanfat\\OneDrive - PT Telekomunikasi Selular\\Tsel work\\Others\\KPU\\dpr\\clean/')

file_list <- list.files()

for (file in file_list){
  dapil = strsplit(file, "_")[[1]][3]
  kota = strsplit(file, "_")[[1]][4]
  # if the merged dataset doesn't exist, create it
  if (!exists("dataset")){
    dataset <- read.table(file, header=TRUE, sep="|")
    dataset$dapil = dapil
    dataset$kota = kota
  }
  
  # if the merged dataset does exist, append to it
  if (exists("dataset")){
    temp_dataset <-read.table(file, header=TRUE, sep="|")
    temp_dataset$dapil = dapil
    temp_dataset$kota = kota
    dataset<-rbind(dataset, temp_dataset)
    rm(temp_dataset)
  }
  
}

save.image(file="all_dpr.RData") 
load("all_dpr.RData")

dat = filter(dataset, !is.na(Tot_Suara))
temp = dat %>% group_by(partai, dapil) %>% summarise(total_suara = sum(Tot_Suara)) %>% mutate(pctg = total_suara/sum(total_suara))

temp_jabar6 = temp %>% 
  ungroup() %>% 
  filter(grepl('jawa barat*', temp$dapil, ignore.case = T)) %>%
  group_by(partai) %>%
  summarise(total_suara= sum(total_suara), pctg = sum(pctg)) %>%
  mutate(pctg_dapil = total_suara/sum(total_suara))
temp_jabar6

library(ggplot2)
ggplot(temp_jabar6, aes(partai, pctg_dapil))+geom_line()+theme(axis.text.x = element_text(angle = 45, hjust = 1))
