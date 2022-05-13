from pandas import read_excel
from docx import Document

import os
from datetime import datetime

def parse_price(price):

  if isinstance(price, str):
    return float(price.replace(",", ".").replace("-", "00").replace("€", ""))

  return price

def format_price(float):

  if isinstance(float, int) or float.is_integer():
    return f"{int(float)},-"
  
  return "{:.2f}".format(round(float, 2)).replace(".", ",")

def parse_float(float_str):

  if isinstance(float_str, str):
    return float(float_str.replace(",", "."))#

  return float_str

def run(config, output_folder_name):

  if not os.path.exists(output_folder_name):
    os.makedirs(output_folder_name)

  schema = read_excel(config.paths.schema)

  print(f"creating {len(schema.head())} bills")

  for _, row in schema.head().iterrows():

    doc = Document(config.paths.template)

    config.currentBillIdx += 1

    hourly = parse_price(row["Stundenlohn (€)"])
    duration = parse_float(row["Dauer (h)"])
    honorar = hourly * duration
    tax = honorar / 100 * 19

    row["_Hourly"] = format_price(hourly)
    row["_Honorar"] = format_price(honorar)
    row["_Tax"] = format_price(tax)
    row["_Total"] = format_price(honorar + tax)
    row["_Date"] = datetime.now().strftime("%d.%m.%Y")
    row["_DateYear"] = datetime.now().strftime("%Y")
    row["_BillNr"] = config.currentBillIdx

    for paragraph in doc.paragraphs:

      for key, value in row.items():

        paragraph.text = paragraph.text.replace(f"#{key}#", str(value))

    formatted_name = row["Nachname"].replace(" ", "_").lower()

    doc.save(f"{output_folder_name}/rechnung_{formatted_name}.docx")

  return config