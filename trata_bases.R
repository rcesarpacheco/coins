library(pacman)
p_load(geojsonR,data.table,rvest,xml2,stringr,dplyr,tidyr,janitor,rebus)
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
fwrite(base,file="bases/base_coins.csv")
