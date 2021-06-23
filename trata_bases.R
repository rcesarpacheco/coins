library(pacman)
p_load(geojsonR,data.table,rvest,xml2,stringr,dplyr,tidyr,janitor,rebus,XML)
setwd('c:/Users/rcesa/Google Drive/Mestrado_FEA/ra/Haddad/')

arquivo <- FROM_GeoJson(url_file_string = "bases/mints.geojson")
arquivo <- unlist(arquivo,recursive = FALSE)
arquivo$type <- NULL
extrai_data_frame <- function(lista) {
  data.frame(name = lista$properties$name,
             type = lista$properties$type,
             uri  = lista$properties$uri,
             long = lista$geometry$coordinates[1],
             lat = lista$geometry$coordinates[2])
}

extrai_codigo_uri <- function(string) {
  posicao <- str_locate(string,'.org/')
  codigo <- str_sub(string,posicao[2]+1,str_length(string)-1)
  return(codigo)
}


lista_dfs <- lapply(arquivo, extrai_data_frame)
df <- do.call("rbind",lista_dfs)
rownames(df) <- NULL
fwrite(df,file = "bases/mints.csv")

arquivo <- FROM_GeoJson(url_file_string = "bases/findspots.geojson")
arquivo <- unlist(arquivo,recursive = FALSE)
arquivo$type <- NULL
lista_dfs <- lapply(arquivo, extrai_data_frame)
df <- do.call("rbind",lista_dfs)
rownames(df) <- NULL



df$codigo_uri <- sapply(df$uri, extrai_codigo_uri)


base <- fread('bases/base_coins.csv')
base$codigo_uri <- sapply(base$`Findspot URI`,extrai_codigo_uri)
base <- base[,.(codigo_uri,`Findspot URI`,RecordId,Title)]

df <- merge(df,base,by='codigo_uri')

fwrite(df,file = "bases/findspot.csv")


# explode bases de findspot para ter uma linha por moeda ------------------

extrai_substr_pattern <- function(string,pattern,final) {
  if (missing(final)) {
    final <- str_length(string)
  }
  posicao <- str_locate(string,pattern)
  codigo <- str_sub(string,posicao[2]+1,final)
  return(codigo)
}

base <- fread('bases/base_coins.csv')
base <- clean_names(base)
base[,numero_moedas:=ifelse(is.na(coin_type_uri)|coin_type_uri=="",0,str_count(coin_type_uri,"\\|\\|")+1)]
num_max_moedas <- max(base$numero_moedas)

base[,paste0('coin_',seq(1,num_max_moedas)):=tstrsplit(coin_type_uri,split="\\|\\|")]

base <- melt(base,variable.name = "coins_numbers",value.name = "coins",id.vars = 1:12)
base[,coins_numbers:=NULL]
base <- base[!is.na(coins),]
base[,ref_coin:=extrai_substr_pattern(coins,"id/"),by = seq_len(nrow(base))]
fwrite(base,file="bases/base_coins_findspots.csv")

# construcao base de moedas -----------------------------------------------
base <- fread('bases/base_coins_findspots.csv',select = c('coins','ref_coin'))
base <- unique(base)
base[,c('date','date_range_start','date_range_end','manufacture','denomination','material','authority','mint','link_mint','obverse_type','obverse_deity','reverse_type','reverse_deity'):=""]

num_moedas <- nrow(base)
for (i in 1:num_moedas) {
  print(i)
  caminho <- base[i,coins]
  xml <- xmlParse(paste0(caminho,'.xml'))
  xml_data <- xmlToList(xml)
  base[i,date:=ifelse(is.null(xml_data$descMeta$typeDesc$date$text),"",xml_data$descMeta$typeDesc$date$text)]
  base[i,date_range_start:=ifelse(is.null(xml_data$descMeta$typeDesc$dateRange$fromDate$text),"",xml_data$descMeta$typeDesc$dateRange$fromDate$text)]
  base[i,date_range_end:=ifelse(is.null(xml_data$descMeta$typeDesc$dateRange$toDate$text),"",xml_data$descMeta$typeDesc$dateRange$toDate$text)]
  base[i,manufacture:=ifelse(is.null(xml_data$descMeta$typeDesc$manufacture$text),"",xml_data$descMeta$typeDesc$manufacture$text)]
  base[i,denomination:=ifelse(is.null(xml_data$descMeta$typeDesc$denomination$text),"",xml_data$descMeta$typeDesc$denomination$text)]
  base[i,material:=ifelse(is.null(xml_data$descMeta$typeDesc$material$text),"",xml_data$descMeta$typeDesc$material$text)]
  base[i,authority:=ifelse(is.null(xml_data$descMeta$typeDesc$authority$persname$text),"",xml_data$descMeta$typeDesc$authority$persname$text)]
  base[i,mint:=ifelse(is.null(xml_data$descMeta$typeDesc$geographic$geogname$text),"",xml_data$descMeta$typeDesc$geographic$geogname$text)]
  base[i,link_mint:=ifelse(is.null(xml_data$descMeta$typeDesc$geographic$geogname$.attrs["href"][1]),"",xml_data$descMeta$typeDesc$geographic$geogname$.attrs["href"][1])]
  base[i,obverse_type:=ifelse(is.null(xml_data$descMeta$typeDesc$obverse$type$description$text),"",xml_data$descMeta$typeDesc$obverse$type$description$text)]
  base[i,obverse_deity:=ifelse(is.null(xml_data$descMeta$typeDesc$obverse$persname$text),"",xml_data$descMeta$typeDesc$obverse$persname$text)]
  base[i,reverse_type:=ifelse(is.null(xml_data$descMeta$typeDesc$reverse$type$description$text),"",xml_data$descMeta$typeDesc$reverse$type$description$text)]
  base[i,reverse_deity:=ifelse(is.null(xml_data$descMeta$typeDesc$reverse$persname$text),"",xml_data$descMeta$typeDesc$reverse$persname$text)]
}

base[date!="",c('date_range_start','date_range_end'):=date]

base[,date:=NULL]


fwrite(base,'bases/base_caracteristicas_moedas.csv')

base_mints_necessarios <- unique(base[,.(mint,link_mint)])
fwrite(base_mints_necessarios,'bases/base_mints_necessarios.csv')


# cruza com localizacoes mints --------------------------------------------

base <- fread('bases/base_caracteristicas_moedas.csv')
base[,id_mint:=extrai_substr_pattern(link_mint,"id/"),by = seq_len(nrow(base))]

base_mints <- fread('bases/mints.csv')

base_mints[,id_mint:=extrai_substr_pattern(uri,"id/"),by = seq_len(nrow(base_mints))]
base_mints[,type:=NULL]
setnames(base_mints,c('lat','long'),c('mint_lat','mint_long'))

base <- merge(base,base_mints,by='id_mint',all.x = T)
fwrite(base,file ='bases/base_caracteristicas_moedas.csv' )

mints_nas <- unique(base[is.na(name),.(mint,link_mint)])

# cruza base moedas findspots com localizacoes dos findspots --------------


base <- fread('bases/base_coins_findspots.csv')
base_findspots <- fread('bases/findspot.csv',select = c('RecordId','long','lat'))
setnames(base_findspots,c('RecordId','long','lat'),c('record_id','findspot_long','findspot_lat'))
base <- merge(base,base_findspots,by='record_id',all.x=T)
fwrite(base,file ='bases/base_coins_findspots.csv' )

