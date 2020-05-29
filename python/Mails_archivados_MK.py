import requests
import numpy as np
import pandas as pd
import pyodbc
import emoji
from sqlalchemy import create_engine, event
import urllib
import time

# Cargamos credenciales y petición a la API
API_KEY = "059a5096-0f48-4a7c-bf20-9fc04344714c"
url = "https://api.hubapi.com/marketing-emails/v1/emails/with-statistics"

# Aquí van los campos que vamos a solicitar
#propiedades = "email,firstname,lastname,cadena,sucursal,canal_preferido,date_of_birth,esfuerzo,gender,socio,tarjeta,company,phone,status_cliente,hs_analytics_first_touch_converting_campaign,hs_analytics_last_touch_converting_campaign,hs_analytics_num_visits,hs_email_delivered,hs_analytics_last_url,hs_email_open,hs_analytics_num_page_views,hs_email_click,hs_email_optout,hs_email_last_email_name,hs_email_last_send_date,hs_analytics_average_page_views"

# Esta es la consulta, contiene las credenciales y las peticiones
querystring = {"limit":"300",
               "archived":"true",
 #              "properties":propiedades,
               "hapikey":API_KEY}

headers = {'accept': 'application/json'}

# Aquí se ejecuta la petición y el resultado se le asigna a la variable response
# luego ese resultado lo convertimos a JSON para poder manipularlo
response = requests.request("GET", url, headers=headers, params=querystring)

respuesta = response.json()

# ----------------- Cargamos los valores a un diccionario MAILS ---------------------

fecha = pd.to_datetime('1753-01-01', format="%Y-%m-%d")
fech = pd.Series(fecha).dt.date

Mails = {'remitente': []
    , 'nombre': []
    , 'asunto': []
    , 'estado': []
    , 'fecha_pub': []
    , 'seleccionados': []
    , 'enviados': []
    , 'entregados': []
    , 'abiertos': []
    , 'bounce': []
    , 'unsubscribed': []
    , 'clicks': []
    , 'spam': []
    , 'pendientes': []
    , 'perdidos': []}

for x in range(len(respuesta['objects'])):
    if 'stats' not in respuesta['objects'][x].keys() or respuesta['objects'][x]['stats']['counters']['sent'] ==0:  # si no se le ha enviado a nadie, no se carga ese correo
        continue
    Mails['remitente'].append(respuesta['objects'][x]['fromName'])
    Mails['nombre'].append(respuesta['objects'][x]['name'])
    Mails['asunto'].append(respuesta['objects'][x]['subject'])
    Mails['estado'].append(respuesta['objects'][x]['state'])
    try:
        Mails['fecha_pub'].append(
            time.strftime('%Y-%m-%d', time.gmtime(respuesta['objects'][x]['publishedAt'] / 1000.0)))  # Publicado
    except:
        Mails['fecha_pub'].append(fech)

    if 'selected' in respuesta['objects'][x].keys():
        Mails['seleccionados'].append(respuesta['objects'][x]['selected'])
    else:
        Mails['seleccionados'].append(0)
    if 'stats' in respuesta['objects'][x].keys():
        Mails['enviados'].append(respuesta['objects'][x]['stats']['counters']['sent'])  # Enviados
        Mails['entregados'].append(respuesta['objects'][x]['stats']['counters']['delivered'])  # Entragados
        Mails['abiertos'].append(respuesta['objects'][x]['stats']['counters']['open'])  # Abiertos
        Mails['bounce'].append(respuesta['objects'][x]['stats']['counters'][
                                   'bounce'])  # Numero de veces que se envió un correo pero no lo recibieron
        Mails['unsubscribed'].append(respuesta['objects'][x]['stats']['counters'][
                                         'unsubscribed'])  # contactos que quitaron su suscripcion a correos
        Mails['clicks'].append(respuesta['objects'][x]['stats']['counters']['click'])  # destinatarios que dieron click
        Mails['spam'].append(respuesta['objects'][x]['stats']['counters']['spamreport'])  # lo marcaron como Spam
        Mails['pendientes'].append(respuesta['objects'][x]['stats']['counters'][
                                       'pending'])  # número de correos que aún intentan alcanzar la bandeja de entrada
        Mails['perdidos'].append(respuesta['objects'][x]['stats']['counters'][
                                     'contactslost'])  # Contactos que anularon suscripción, marcaron spam o dirección inválida
    else:
        Mails['enviados'].append(0)  # Enviados
        Mails['entregados'].append(0)  # Entragados
        Mails['abiertos'].append(0)  # Abiertos
        Mails['bounce'].append(0)  # Numero de veces que se envió un correo pero no lo recibieron
        Mails['unsubscribed'].append(0)  # contactos que quitaron su suscripcion a correos
        Mails['clicks'].append(0)  # destinatarios que dieron click
        Mails['spam'].append(0)  # lo marcaron como Spam
        Mails['pendientes'].append(0)  # número de correos que aún intentan alcanzar la bandeja de entrada
        Mails['perdidos'].append(0)  # Contactos que anularon suscripción, marcaron spam o dirección inválida

# lo cargamos en un DataFrame en Pandas

DF = pd.DataFrame(Mails)

# --------------Limpiamos el campo de subject de Emojis
# Función que limpiará el texto
def give_emoji_free_text(text):
    if type(text)==str:
        allchars = [str for str in text]
        emoji_list = [c for c in allchars if c in emoji.UNICODE_EMOJI]
        clean_text = ' '.join([str for str in text.split() if not any(i in str for i in emoji_list)])
        return clean_text

# Captamos el texto del campo en un diccionario que nos servirá para reemplazar los valores mediante un método Python

emo = {x:'' for x in DF['asunto'].unique().tolist() if x not in ['',None]}

for y in list(emo.keys()):
    emo[y]= give_emoji_free_text(y)

#Quitamos emojis y actualizamos
DF['asunto'].replace(emo,inplace=True)

# ---------- Insertamos los registros ----------------------

server = 'tcp:190.27.1.13\BI'
database = 'dbHighLife'
username = 'srodriguez'
password = 'Zmadgfv1'

#pyodbc
cnxn = pyodbc.connect('DRIVER={ODBC Driver 11 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()

cursor.execute(" truncate table CRM_Mails_archived")
cnxn.commit()

insercion = """ insert into CRM_Mails_archived values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"""

cursor.executemany(insercion,DF[DF['estado']!='DRAFT'].values.tolist())
cnxn.commit()

cursor.execute(""" exec [dbo].[insert_Hist_procesos] 'Mail archived HubSpot' """)
cnxn.commit()

cursor.close()
cnxn.close()
