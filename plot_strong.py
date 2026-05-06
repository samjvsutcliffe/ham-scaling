import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import re

output_regex = re.compile("data_.*STRONG.*\.csv")                                 
output_list = list(filter(output_regex.match,os.listdir("./")))
output_list.sort()
#if len(output_list) == 1:
#    data_file = output_list[0]
#else:
#    for i,out in enumerate(output_list):                                    
#        print("{}: {}".format(i,out))                                       
#    data_file = output_list[int(input())]

plt.figure()
for data_file in output_list:
    df = pd.read_csv(data_file)
    numeric_cols = ["threads", "refine","throughput","mp-throughput"]
    df[numeric_cols] = df[numeric_cols].apply(pd.to_numeric)
    for solver,row in df.groupby("solver"):
        for refines,row in row.groupby("refine"):
            name =  "{} - {}".format(data_file,solver)
            print(name)
            print(refines)
            means = row.groupby("threads")["throughput"].mean()
            print(means)
            vs=means.values/means.values[0]
            plt.plot(means.index.values,vs,label="{} {}".format(name,refines))
    #plt.scatter(row["threads"].index.values,row["threads"].values,label=name)
    #plt.plot(means.index,means.index,label="Ideal",ls="--")

ax = plt.gca()
ax.axline((0,0),slope=1,label="Ideal",ls="--",c="black")
plt.legend()
plt.xscale("log")
plt.yscale("log")
plt.xlabel("Threads")
plt.ylabel("Speedup")
plt.show()

#means = df.groupby("threads")["mp-throughput"].mean()

