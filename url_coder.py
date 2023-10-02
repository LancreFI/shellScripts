import sys
from urllib.parse import unquote
from urllib.parse import quote_plus

def usage():
  print ("Usage: python url_coder.py <encode|decode> string")

try:
  if sys.argv[2] != "":
    inputstr=sys.argv[2]
except:
  usage()
  sys.exit()

try:
  if sys.argv[1] == "decode":
    print (unquote(inputstr))
  elif sys.argv[1] == "encode":
    print (quote_plus(inputstr))
  else:
    usage()
except:
  usage()
  sys.exit()

