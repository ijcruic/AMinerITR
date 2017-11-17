# -*- coding: utf-8 -*-
#! python3
"""
Created on Thu Nov 16 13:50:31 2017

@author: icruicks
"""
import pandas as pd

def gen():
    with open('AMiner-Paper.txt', 'r',  encoding="utf8") as f:
        datum={}
        citations =0
        row=0
        readFile = f.readlines()
        for line in readFile:
            
            if '#index' in line:
                if bool(datum):
                    datum['citations'] = citations
                    try:
                        for i in range(len(datum['author'])):
                            
                            datum_to_save = datum.copy()
                            datum_to_save['author']=datum['author'][i]
                            datum_to_save['affiliation']=datum['affiliation'][i]
                            yield datum_to_save
                            row+=1
                    except IndexError as e:
                        continue
                    
                    datum={}
                    citations =0
                datum['id'] = line[7:].rstrip()
                
            elif '#*' in line:
                datum['title'] = line[3:].rstrip()
            elif '#@' in line:
                datum['author'] = line[3:].rstrip().rsplit(";")
            elif '#o' in line:
                datum['affiliation'] = line[3:].rstrip().rsplit(";")
            elif '#t' in line:
                datum['year'] = line[3:].rstrip()
            elif '#c' in line:
                datum['venue'] = line[3:].rstrip()
            elif '#%' in line:
                citations +=1
            elif '#!' in line:
                datum['abstract'] = line[3:].rstrip()


data = pd.DataFrame(gen(), columns =('id', 'title', 'author', 'affiliation', 'year', 
                                  'venue', 'citations', 'abstract'))
data['year'] =pd.to_numeric(data['year'], errors = 'coerce').fillna(0)

data.to_csv("AMiner.csv", encoding='utf-8')