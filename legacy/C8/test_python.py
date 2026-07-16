import os,sys,platform
import sysconfig

print("Testing python {}".format(platform.python_version()))
print("Include Path: {}".format(sysconfig.get_path('include')))
print("Test pass")