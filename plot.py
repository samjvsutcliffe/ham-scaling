import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import re

output_regex = re.compile("data_.*\.csv")                                 
output_list = list(filter(output_regex.match,os.listdir("./")))
output_list.sort()
if len(output_list) == 1:
    data_file = output_list[0]
else:
    for i,out in enumerate(output_list):                                    
        print("{}: {}".format(i,out))                                       
    data_file = output_list[int(input())]

df = pd.read_csv(data_file)

numeric_cols = ["threads", "refine","throughput","mp-throughput"]
df[numeric_cols] = df[numeric_cols].apply(pd.to_numeric)

plt.figure()
for name,row in df.groupby("solver"):
    #print(row)
    #print(k)
    print(name)
    means = row.groupby("threads")["mp-throughput"].mean()
    print(means)
    vs=means.values/means.values[0]
    plt.plot(means.index.values,vs,label=name)
    plt.plot(means.index,means.index,label="Optimal")
plt.legend()
plt.xscale("log")
plt.yscale("log")
plt.show()

#means = df.groupby("threads")["mp-throughput"].mean()

