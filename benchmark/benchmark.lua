-- benchmark of common models
local d = require 'autograd'
local nn = require 'nn'
local c = require 'trepl.colorize'
local getValue = require 'autograd.node'.getValue

-- Test 1: logistic regression
local tests = {
   logistic = function()
      local tnn, tag
      local x = torch.FloatTensor(1000,100):normal()
      local y = torch.FloatTensor(1000):random(1,10)
      local yOneHot = d.util.oneHot(y,10)

      do
         local model = nn.Sequential()
         model:add(nn.Linear(100,10))
         model:add(nn.LogSoftMax())
         model:float()
         local lossf = nn.ClassNLLCriterion()
         lossf:float()

         sys.tic()
         for k = 1,10 do
            for i = 1,x:size(1) do
               model:zeroGradParameters()
               local yhat = model:forward(x[i])
               local loss = lossf:forward(yhat, y[i])
               local dloss_dyhat = lossf:backward(yhat, y[i])
               model:backward(x[i], dloss_dyhat)
            end
         end
         tnn = sys.toc()
      end

      do
         local f = function(params, x, y)
            local wx = params.W * x + params.b
            local loss, yhat = d.loss.crossEntropy(wx, y)
            return loss
         end
         local params = {
            W = torch.FloatTensor(10, 100):normal(.01),
            b = torch.FloatTensor(10):zero(),
         }

         sys.tic()
         for k = 1,10 do
            for i = 1,x:size(1) do
               local grads = d(f)(params, x[i], yOneHot[i])
            end
         end
         tag = sys.toc()
      end

      return tnn, tag
   end,

   mlp = function()
      local tnn, tag
      local x = torch.FloatTensor(1000,100):normal()
      local y = torch.FloatTensor(1000):random(1,10)
      local yOneHot = d.util.oneHot(y,10)

      do
         local model = nn.Sequential()
         model:add(nn.Linear(100,1000))
         model:add(nn.Tanh())
         model:add(nn.Linear(1000,10))
         model:add(nn.LogSoftMax())
         model:float()
         local lossf = nn.ClassNLLCriterion()
         lossf:float()

         sys.tic()
         for i = 1,x:size(1) do
            model:zeroGradParameters()
            local yhat = model:forward(x[i])
            local loss = lossf:forward(yhat, y[i])
            local dloss_dyhat = lossf:backward(yhat, y[i])
            model:backward(x[i], dloss_dyhat)
         end
         tnn = sys.toc()
      end

      do
         local f = function(params, x, y)
            local h1 = torch.tanh( params.W1 * x + params.b1 )
            local h2 = params.W2 * h1 + params.b2
            local loss, yhat = d.loss.crossEntropy(h2, y)
            return loss
         end
         local params = {
            W1 = torch.FloatTensor(1000, 100):normal(.01),
            b1 = torch.FloatTensor(1000):zero(),
            W2 = torch.FloatTensor(10, 1000):normal(.01),
            b2 = torch.FloatTensor(10):zero(),
         }

         sys.tic()
         for i = 1,x:size(1) do
            local grads = d(f)(params, x[i], yOneHot[i])
         end
         tag = sys.toc()
      end

      return tnn, tag
   end,

   mlpHybrid = function()
      local tnn, tag
      local x = torch.FloatTensor(1000,100):normal()
      local y = torch.FloatTensor(1000):random(1,10)
      local yOneHot = d.util.oneHot(y,10)

      do
         local model = nn.Sequential()
         model:add(nn.Linear(100,1000))
         model:add(nn.Tanh())
         model:add(nn.Linear(1000,10))
         model:add(nn.LogSoftMax())
         model:float()
         local lossf = nn.ClassNLLCriterion()
         lossf:float()

         sys.tic()
         for i = 1,x:size(1) do
            model:zeroGradParameters()
            local yhat = model:forward(x[i])
            local loss = lossf:forward(yhat, y[i])
            local dloss_dyhat = lossf:backward(yhat, y[i])
            model:backward(x[i], dloss_dyhat)
         end
         tnn = sys.toc()
      end

      do
         local lin1 = d.nn.Linear(100,1000)
         local tanh = d.nn.Tanh()
         local lin2 = d.nn.Linear(1000,10)
         local lsm = d.nn.LogSoftMax()

         local f = function(params, x, y)
            local h1 = tanh( lin1(x, params.W1, params.b1) )
            local h2 = lin2(h1, params.W2, params.b2)
            local yhat = lsm(h2)
            local loss = -torch.sum(torch.cmul(yhat, y))
            return loss
         end
         local params = {
            W1 = torch.FloatTensor(1000, 100):normal(.01),
            b1 = torch.FloatTensor(1000):zero(),
            W2 = torch.FloatTensor(10, 1000):normal(.01),
            b2 = torch.FloatTensor(10):zero(),
         }

         sys.tic()
         for i = 1,x:size(1) do
            local grads = d(f)(params, x[i], yOneHot[i])
         end
         tag = sys.toc()
      end

      return tnn, tag
   end,

   mlpForward = function()
      local tnn, tag
      local x = torch.FloatTensor(1000,100):normal()
      local y = torch.FloatTensor(1000):random(1,10)
      local yOneHot = d.util.oneHot(y,10)

      do
         local model = nn.Sequential()
         model:add(nn.Linear(100,1000))
         model:add(nn.Tanh())
         model:add(nn.Linear(1000,10))
         model:add(nn.LogSoftMax())
         model:float()
         local lossf = nn.ClassNLLCriterion()
         lossf:float()

         sys.tic()
         for k = 1,10 do
            for i = 1,x:size(1) do
               model:zeroGradParameters()
               local yhat = model:forward(x[i])
               local loss = lossf:forward(yhat, y[i])
            end
         end
         tnn = sys.toc()
      end

      do
         local f = function(params, x, y)
            local h1 = torch.tanh( params.W1 * x + params.b1 )
            local h2 = params.W2 * h1 + params.b2
            local loss, yhat = d.loss.crossEntropy(h2, y)
            return loss
         end
         local params = {
            W1 = torch.FloatTensor(1000, 100):normal(.01),
            b1 = torch.FloatTensor(1000):zero(),
            W2 = torch.FloatTensor(10, 1000):normal(.01),
            b2 = torch.FloatTensor(10):zero(),
         }

         sys.tic()
         for k = 1,10 do
            for i = 1,x:size(1) do
               local grads = f(params, x[i], yOneHot[i])
            end
         end
         tag = sys.toc()
      end

      return tnn, tag
   end,

   mlpBatched = function()
      local tnn, tag
      local x = torch.FloatTensor(32,100):normal()
      local y = torch.FloatTensor(32):random(1,10)
      local yOneHot = d.util.oneHot(y,10)

      do
         local model = nn.Sequential()
         model:add(nn.Linear(100,1000))
         model:add(nn.Tanh())
         model:add(nn.Linear(1000,10))
         model:add(nn.LogSoftMax())
         model:float()
         local lossf = nn.ClassNLLCriterion()
         lossf:float()

         -- force allocs
         local yhat = model:forward(x)
         local loss = lossf:forward(yhat, y)
         local dloss_dyhat = lossf:backward(yhat, y)
         model:backward(x, dloss_dyhat)

         sys.tic()
         for i = 1,100 do
            model:zeroGradParameters()
            local yhat = model:forward(x)
            local loss = lossf:forward(yhat, y)
            local dloss_dyhat = lossf:backward(yhat, y)
            model:backward(x, dloss_dyhat)
         end
         tnn = sys.toc()
      end

      do
         local f = function(params, x, y)
            local N = getValue(x):size(1)
            local h1 = torch.tanh( x * params.W1 + torch.expand(params.b1, N,1000) )
            local h2 = h1 * params.W2 + torch.expand(params.b2, N,10)
            local loss, yhat = d.loss.crossEntropy(h2, y)
            return loss
         end
         local params = {
            W1 = torch.FloatTensor(1000, 100):normal(.01):t(),
            b1 = torch.FloatTensor(1, 1000):zero(),
            W2 = torch.FloatTensor(10, 1000):normal(.01):t(),
            b2 = torch.FloatTensor(1, 10):zero(),
         }

         sys.tic()
         for i = 1,100 do
            local grads = d(f)(params, x, yOneHot)
         end
         tag = sys.toc()
      end

      return tnn, tag
   end,

   mlpHybridBatched = function()
      local tnn, tag
      local x = torch.FloatTensor(32,100):normal()
      local y = torch.FloatTensor(32):random(1,10)
      local yOneHot = d.util.oneHot(y,10)

      do
         local model = nn.Sequential()
         model:add(nn.Linear(100,1000))
         model:add(nn.Tanh())
         model:add(nn.Linear(1000,10))
         model:add(nn.LogSoftMax())
         model:float()
         local lossf = nn.ClassNLLCriterion()
         lossf:float()

         sys.tic()
         for i = 1,100 do
            model:zeroGradParameters()
            local yhat = model:forward(x)
            local loss = lossf:forward(yhat, y)
            local dloss_dyhat = lossf:backward(yhat, y)
            model:backward(x, dloss_dyhat)
         end
         tnn = sys.toc()
      end

      do
         local lin1 = d.nn.Linear(100,1000)
         local tanh = d.nn.Tanh()
         local lin2 = d.nn.Linear(1000,10)
         local lsm = d.nn.LogSoftMax()

         local f = function(params, x, y)
            local h1 = tanh( lin1(x, params.W1, params.b1) )
            local h2 = lin2(h1, params.W2, params.b2)
            local yhat = lsm(h2)
            local loss = -torch.sum(torch.cmul(yhat, y))
            return loss
         end
         local params = {
            W1 = torch.FloatTensor(1000, 100):normal(.01),
            b1 = torch.FloatTensor(1000):zero(),
            W2 = torch.FloatTensor(10, 1000):normal(.01),
            b2 = torch.FloatTensor(10):zero(),
         }

         sys.tic()
         for i = 1,100 do
            local grads = d(f)(params, x, yOneHot)
         end
         tag = sys.toc()
      end

      return tnn, tag
   end,

   cnnHybridBatched = function()
      local tnn, tag
      local x = torch.FloatTensor(32,3,64,64):normal()
      local y = torch.FloatTensor(32):random(1,10)
      local yOneHot = d.util.oneHot(y,10)

      do
         local model = nn.Sequential()
         model:add(nn.SpatialConvolutionMM(3,16,5,5))
         model:add(nn.Tanh())
         model:add(nn.SpatialMaxPooling(2,2,2,2))
         model:add(nn.SpatialConvolutionMM(16,32,5,5))
         model:add(nn.Tanh())
         model:add(nn.SpatialMaxPooling(2,2,2,2))
         model:add(nn.Reshape(13*13*32))
         model:add(nn.Linear(13*13*32,10))
         model:add(nn.LogSoftMax())
         model:float()
         local lossf = nn.ClassNLLCriterion()
         lossf:float()

         sys.tic()
         for i = 1,10 do
            model:zeroGradParameters()
            local yhat = model:forward(x)
            local loss = lossf:forward(yhat, y)
            local dloss_dyhat = lossf:backward(yhat, y)
            model:backward(x, dloss_dyhat)
         end
         tnn = sys.toc()
      end

      do
         local c1 = d.nn.SpatialConvolutionMM(3,16,5,5)
         local t1 = d.nn.Tanh()
         local m1 = d.nn.SpatialMaxPooling(2,2,2,2)
         local c2 = d.nn.SpatialConvolutionMM(16,32,5,5)
         local t2 = d.nn.Tanh()
         local m2 = d.nn.SpatialMaxPooling(2,2,2,2)
         local r = d.nn.Reshape(13*13*32)
         local l3 = d.nn.Linear(13*13*32,10)
         local lsm = d.nn.LogSoftMax()

         local f = function(params, x, y)
            local h1 = m1( t1( c1(x, params.W1, params.b1) ) )
            local h2 = m2( t2( c2(h1, params.W2, params.b2) ) )
            local h3 = l3(r(h2), params.W3, params.b3)
            local yhat = lsm(h3)
            local loss = -torch.sum(torch.cmul(yhat, y))
            return loss
         end
         local params = {
            W1 = torch.FloatTensor(16, 3*5*5):normal(.01),
            b1 = torch.FloatTensor(16):zero(),
            W2 = torch.FloatTensor(32, 16*5*5):normal(.01),
            b2 = torch.FloatTensor(32):zero(),
            W3 = torch.FloatTensor(10, 32*13*13):normal(.01),
            b3 = torch.FloatTensor(10):zero(),
         }

         sys.tic()
         for i = 1,10 do
            local grads = d(f)(params, x, yOneHot)
         end
         tag = sys.toc()
      end

      return tnn, tag
   end,
}

local fmt = function(nb,color)
   local nb = stringx.rjust(string.format('%.2f',nb), 5)
   return c[color](nb)
end

print('Benchmarks:')
for name,test in pairs(tests) do
   local tnn,tag = test()
   print(c.blue(stringx.rjust('['..name..']', 20))
      .. ' nn: ' .. fmt(tnn,'yellow') .. 's, autograd: ' .. fmt(tag,'red') .. 's, ratio: ' .. fmt(tag/tnn,'green') .. 'x')
end
