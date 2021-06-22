from selenium import webdriver
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import time
caminho = "C:/Users/rcesa/Google Drive/Mestrado_FEA/RA/Haddad"

base = pd.read_csv('C:/Users/rcesa/Google Drive/Mestrado_FEA/RA/Haddad/bases/base_findspots.csv')
browser=webdriver.Firefox()
base['latitude'] = np.nan
base['longitude'] = np.nan

for row in base.index:
    url = base.loc[row,'Findspot URI']
    if not pd.isna(url):
        browser.get(url)
        time.sleep(5)
        soup=BeautifulSoup(browser.page_source)
        base.at[row,'latitude']    = soup.find(title='latitude').text
        base.at[row,'longitude']  = soup.find(title='longitude').text


base.to_csv('C:/Users/rcesa/Google Drive/Mestrado_FEA/RA/Haddad/bases/extract_findspots_geonames.csv',index=False)
