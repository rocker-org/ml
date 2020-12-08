## Load required packages
require(mlbench)
require(mxnet)
require(tictoc) #install.packages("tictoc")

## Options:
nHidden <- 100
nRounds <- 200
batchSize <- 32

## Classification VS Regression GPU-speedup example
data(Sonar, package="mlbench")
Sonar[,61] = as.numeric(Sonar[,61])-1
train.ind = c(1:50, 100:150)
train.x = data.matrix(Sonar[train.ind, 1:60])
train.y = Sonar[train.ind, 61]
test.x = data.matrix(Sonar[-train.ind, 1:60])
test.y = Sonar[-train.ind, 61]

tic("Classification CPU time:")
mx.set.seed(0)
model <- mx.mlp(train.x, train.y, hidden_node=nHidden, out_node=2,
                out_activation="softmax", num.round=nRounds,
                array.batch.size=batchSize, learning.rate=0.07, momentum=0.9, 
                eval.metric=mx.metric.accuracy, array.layout="rowmajor",
                ctx=mx.cpu(), verbose=FALSE
)
toc()

tic("Classification GPU time:")
mx.set.seed(0)
model <- mx.mlp(train.x, train.y, hidden_node=nHidden, out_node=2,
                out_activation="softmax", num.round=nRounds,
                array.batch.size=batchSize, learning.rate=0.07, momentum=0.9, 
                eval.metric=mx.metric.accuracy, array.layout="rowmajor",
                ctx=mx.gpu(), verbose=FALSE
)
toc()

tic("Regression CPU time:")
mx.set.seed(0)
model <- mx.mlp(train.x, train.y, hidden_node=5*nHidden, out_node=1,
                out_activation="rmse", num.round=10*nRounds,
                array.batch.size=batchSize, learning.rate=0.07, momentum=0.9, 
                eval.metric=mx.metric.rmse, array.layout="rowmajor",
                ctx=mx.cpu(), verbose=FALSE
)
toc()

tic("Regression GPU time:")
mx.set.seed(0)
model <- mx.mlp(train.x, train.y, hidden_node=5*nHidden, out_node=1,
                out_activation="rmse", num.round=10*nRounds,
                array.batch.size=batchSize, learning.rate=0.07, momentum=0.9, 
                eval.metric=mx.metric.rmse, array.layout="rowmajor",
                ctx=mx.gpu(), verbose=FALSE
)
toc()