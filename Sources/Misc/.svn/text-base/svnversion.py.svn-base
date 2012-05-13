import os
v = os.popen("svnversion").read()
if v.find(":") <> -1: v = v.split(":")[1]
v = v[:-1]
if v[-1] == 'M': v = v[:-1]
cmd = """echo '#define SVN_VERSION @"%s"' > svnversion.h""" % (v,)
os.system(cmd)
