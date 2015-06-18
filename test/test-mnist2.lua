-- as you can see, you will need to 'luarocks install mnist' first

require 'nn'
require 'sys'
local mnist = require 'mnist'

local _trainset = mnist.traindataset()
--local _testset = mnist.testdataset()

local train_data = _trainset.data
local train_labels = _trainset.label

local batchSize = 128
--print('batch_labels\n', batch_labels)

--print(batch_labels[1])
--print(batch_data[1])

local numBatches = 10

local trainset = {}
function trainset.size()
  return numBatches
end

i = 1
for b=1,numBatches do
  local batch_data = torch.Tensor(batchSize, 28*28)
  batch_data = batch_data / 255 - 0.5
  local batch_labels = torch.Tensor(batchSize, 10)
  for bi=1,batchSize do
    batch_data[bi] = torch.reshape(train_data[i], 28 * 28):double()
    batch_labels[bi]:zero()
    local label = train_labels[i]
    if label == 0 then
      label = 10
    end
    batch_labels[bi][label] = 1
    i = i + 1
  end
  table.insert(trainset, {batch_data, batch_labels})
end

api = os.getenv('API')
print('api', api)

learningRate = 0.01

local net = nn.Sequential()
net:add(nn.Linear(28*28,150))
net:add(nn.Tanh())
net:add(nn.Linear(150,10))

if api == 'cpu' then
local criterion = nn.MSECriterion()
local trainer = nn.StochasticGradient(net, criterion)
trainer.learningRate = learningRate
sys.tic()
trainer:train(trainset)
print('toc', sys.toc())
end

if api == 'cl' then
require 'clnn'
local trainsetcl = {}
function trainsetcl.size()
  return 10
end
for b=1,numBatches do
  table.insert(trainsetcl, {trainset[b][1]:clone():cl(), trainset[b][2]:clone():cl()})
end
local netcl = net:cl()
local criterioncl = nn.MSECriterion():cl()
local trainercl = nn.StochasticGradient(netcl, criterioncl)
trainercl.learningRate = learningRate
sys.tic()
trainercl:train(trainsetcl)
print('toc', sys.toc())
end

if api == 'cuda' then
require 'cunn'
local trainsetcuda = {}
function trainsetcuda.size()
  return 10
end
for b=1,numBatches do
  table.insert(trainsetcuda, {trainset[b][1]:clone():cuda(), trainset[b][2]:clone():cuda()})
end
local netcuda = net:cuda()
local criterioncuda = nn.MSECriterion():cuda()
local trainercuda = nn.StochasticGradient(netcuda, criterioncuda)
trainercuda.learningRate = learningRate
sys.tic()
trainercuda:train(trainsetcuda)
print('toc', sys.toc())
end
