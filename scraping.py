from selenium import webdriver
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import time
caminho = "C:/Users/rcesa/Google Drive/Mestrado_FEA/RA/Haddad"

base = pd.read_csv('C:/Users/rcesa/Google Drive/Mestrado_FEA/RA/Haddad/bases/base_findspots.csv')
browser=webdriver.Chrome()
base['latitude'] = np.nan
base['longitude'] = np.nan

for row in base.index:
    url = base.loc[row,'Findspot URI']
    if not pd.isna(url):
        base.at[row,'latitude']    = soup.find(title='latitude').text
        base.at[row,'longitude']  = soup.find(title='longitude').text

base.to_csv('C:/Users/rcesa/Google Drive/Mestrado_FEA/RA/Haddad/bases/extract_findspots_geonames.csv',index=False)




# extraindo caracteristicas medias das moedas
browser=webdriver.Chrome()
base = pd.read_csv('C:/Users/rcesa/Google Drive/Mestrado_FEA/RA/Haddad/bases/base_caracteristicas_moedas.csv')
base['mean_axis'] = np.nan
base['mean_diameter'] = np.nan
base['mean_weigth'] = np.nan
for row in base.index:
    url = base.loc[row,'coins']
    browser.get(url)
    time.sleep(5)
    soup=BeautifulSoup(browser.page_source)
    try:
        base.at[row,'mean_axis']    = soup.find(text="Average measurements for this coin type:").parent.parent.find(text='Axis').next.next.text
    except:
        pass
    try:
        base.at[row,'mean_diameter']  = soup.find(text="Average measurements for this coin type:").parent.parent.find(text='Diameter').next.next.text
    except:
        pass
    try:
        base.at[row,'mean_weigth']  = soup.find(text="Average measurements for this coin type:").parent.parent.find(text='Weight').next.next.text
    except:
        pass

base.to_csv('C:/Users/rcesa/Google Drive/Mestrado_FEA/RA/Haddad/bases/base_caracteristicas_moedas2.csv',index=False)
