library(rvest)
library(dplyr)
library(XML)
library(reshape2)

setwd('C:\\Users\\ghilmanfat\\OneDrive - PT Telekomunikasi Selular\\Tsel work\\Others\\KPU\\dpr')
js_scrape <- function(
  x = 0,
  y = 0,
  js_path = "casper_kpu.js", 
  casperpath = "casperjs")
{
  
  lines <- readLines(js_path)
  lines[62] <- paste0("\tselectedDapil = dapilOptions[", x, "];")
  lines[63] <- paste0("\tselectedDapil_nm = dapilName[", x, "];")
  lines[92] <- paste0("\t\tselectedKab = kabOptions[", y, "];")                                                                               
  lines[93] <- paste0("\t\tselectedKab_nm = kabName[", y, "];")
  writeLines(lines, js_path)
  
  command = paste(casperpath, js_path, sep = " ")
  system(command)
  
}

link = read_html("https://pemilu2014.kpu.go.id/db1_dpr.php")
dapil_id = link %>% html_nodes(xpath =  '//*[@name="wilayah_id"]/option') %>% html_attr("value")
dapil = cbind(dapil_id, dapil = link %>% html_nodes(xpath =  '//*[@name="wilayah_id"]/option') %>% html_text()) %>% data.frame() %>% filter(dapil_id!="")

i_null=j_null=vector()
for(i in 1:(nrow(dapil)-1)){
  link = read_html(paste0("https://pemilu2014.kpu.go.id/db1_dpr.php?cmd=select_1&grandparent=0&parent=", dapil$dapil_id[i+1]))
  city_id = link %>% html_nodes(xpath =  '//*[@name="wilayah_id"]/option') %>% html_attr("value")
  city = cbind(city_id, city = link %>% html_nodes(xpath =  '//*[@name="wilayah_id"]/option') %>% html_text()) %>% data.frame() %>% filter(city_id!="")
  
  for(j in 0:(nrow(city)-1)){
    js_scrape(x = i, y = j)
    
    possibleError = tryCatch({
      dat = read_html(paste(dapil$dapil_id[i+1], city$city_id[j+1], dapil$dapil[i+1], city$city[j+1], 'dpr.html', sep = "_"))
      #dat = read_html("raw_html/760_27026_JAWA BARAT III_CIANJUR_dpr.html")
      dat = dat %>% html_nodes('#daftartps > table') %>% html_table(fill = T, header = T)
      dat = dat[[length(dat)]][-1,]
      colnames(dat) = dat[1,]
      dat = dat[-1,-which(names(dat) %in% c('NA'))]
      colnames(dat) = c(colnames(dat)[-grep('Kecamatan', colnames(dat))], 'total')
      rownames(dat) = NULL
      dat$total = NULL
      
      index_partai = grep('PARTAI', dat$`No. Urut`)
      # create new column party
      dat$partai = ''
      for(x in 1:length(index_partai)){
        if(x == length(index_partai)){
          dat$partai[index_partai[x]:nrow(dat)] = dat[index_partai[x],1]
        }else{
          dat$partai[index_partai[x]:index_partai[x+1]] = dat[index_partai[x],1]
        }
      }
    },
    error = function(e) e)
    if(inherits(possibleError, "error")){
      i_null = c(i_null, i)
      j_null = c(j_null, j)
      print(paste("error", i, j))
      next
    }
    
    dat$`No. Urut`[index_partai] = 0 
    dat$`No. Urut` = as.integer(dat$`No. Urut`)
    # delete total rows and rows which has blank values
    dat = dat[-c(which(is.na(dat$`No. Urut`))),]
    dat = melt(dat, id=c("No. Urut", "ID", "Caleg", "partai"), variable.name = "Kecamatan", value.name = "Tot_Suara")
    write.table(dat, paste0("clean/", paste(dapil$dapil_id[i+1], city$city_id[j+1], dapil$dapil[i+1], city$city[j+1], 'dpr_clean.csv', sep = "_")), sep = "|", row.names = F, quote = F)
    file.rename(from = paste(dapil$dapil_id[i+1], city$city_id[j+1], dapil$dapil[i+1], city$city[j+1], 'dpr.html', sep = "_"), 
                to = paste0("raw_html/", paste(dapil$dapil_id[i+1], city$city_id[j+1], dapil$dapil[i+1], city$city[j+1], 'dpr.html', sep = "_")))
    print(paste('written to csv', paste(dapil$dapil_id[i+1], city$city_id[j+1], dapil$dapil[i+1], city$city[j+1], 'dpr.html', sep = "_")))
  }
}

kota = terverifikasi = belum_terverifikasi = jumlah_form = vector()
for(x in 1:nrow(dapil)){
  link = read_html(paste0("https://pemilu2014.kpu.go.id/db1_dpr.php?cmd=select_1&grandparent=0&parent=", dapil$dapil_id[x]))
  link = link %>% html_nodes('div.formcontainer:nth-child(1) > span:nth-child(2)') %>% html_text()
  kota = c(kota, gsub(pattern = '\r\n\t\t(.+):.+', replacement = '\\1', x = link))
  terverifikasi = c(terverifikasi, gsub(pattern = '.+([0-9]){1,} Terverifikasi .+', replacement = '\\1', x = link))
  belum_terverifikasi = c(belum_terverifikasi,gsub(pattern = '.+([0-9]){1,} Belum Terverifikasi .+', replacement = '\\1', x = link))
  jumlah_form = c(jumlah_form,gsub(pattern = '.+([0-9]){1,} Jumlah Form.+', replacement = '\\1', x = link))
  
}

df_form = data.frame(kota = kota, terverifikasi = terverifikasi, belum_terverifikasi = belum_terverifikasi, jumlah_form = jumlah_form)
final_df = left_join(dataset, df_form, by = c('kota'='kota'))

write.table(final_df,'all_dpr_2014.csv', sep = "|", row.names = F, quote = F)