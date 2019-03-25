#!/usr/bin/python
import datetime

table = "[dbo].[calendar]"

def calc_sunday(year):
  a = year % 19
  b = year >> 2
  c = b // 25 + 1
  d = (c * 3) >> 2
  e = ((a * 19) - ((c * 8 + 5) // 25) + d + 15) % 30
  e += (29578 - a - e * 32) >> 10
  e -= ((year % 7) + b - d + e + 2) % 7
  d = e >> 5
  day = e - d * 31
  month = d + 3
  retval = str(year) + str(month).rjust(2,'0') + str(day).rjust(2,'0')
  return retval

def calc_friday(year):
  a = year % 19
  b = year >> 2
  c = b // 25 + 1
  d = (c * 3) >> 2
  e = ((a * 19) - ((c * 8 + 5) // 25) + d + 15) % 30
  e += (29578 - a - e * 32) >> 10
  e -= ((year % 7) + b - d + e + 2) % 7
  d = e >> 5
  day = e - d * 31
  month = d + 3

  retval = str(year) + str(month).rjust(2,'0') + str(day).rjust(2,'0')
  sunday = datetime.datetime.strptime(retval, "%Y%m%d")
  friday = sunday - datetime.timedelta(days=2)
  return friday.strftime('%Y%m%d')

def calc_monday(year):
  a = year % 19
  b = year >> 2
  c = b // 25 + 1
  d = (c * 3) >> 2
  e = ((a * 19) - ((c * 8 + 5) // 25) + d + 15) % 30
  e += (29578 - a - e * 32) >> 10
  e -= ((year % 7) + b - d + e + 2) % 7
  d = e >> 5
  day = e - d * 31
  month = d + 3

  retval = str(year) + str(month).rjust(2,'0') + str(day).rjust(2,'0')
  sunday = datetime.datetime.strptime(retval, "%Y%m%d")
  monday = sunday + datetime.timedelta(days=1)
  return monday.strftime('%Y%m%d')

def make_queries():
  in_str = '(';
  for i in range(1900,2999):
    in_str += str(calc_monday(i)) + ","

  in_str += calc_monday(2999) + ")"
  sql1 = "UPDATE " + table + " SET IsHolidayAUS = 1, HolidayAUS = 'Easter Monday' WHERE [DateKey] IN " + in_str + "; "

  in_str = '(';
  for i in range(1900,2999):
    in_str += str(calc_sunday(i)) + ","

  in_str += calc_monday(2999) + ")"
  sql2 = "UPDATE " + table + " SET IsHolidayAUS = 1, HolidayAUS = 'Easter Sunday' WHERE [DateKey] IN " + in_str + "; "

  in_str = '(';
  for i in range(1900,2999):
    in_str += str(calc_friday(i)) + ","

  in_str += calc_monday(2999) + ")"
  sql3 = "UPDATE " + table + " SET IsHolidayAUS = 1, HolidayAUS = 'Easter Friday' WHERE [DateKey] IN " + in_str + "; "
  return sql1 + '\n' + sql2 + '\n' + sql3 + '\n'

print(make_queries())
