require 'package'
package.path = package.path .. ";../../?.lua" -- add to path

require 'ro_conv'
require 'ro_linear'
require 'nn'
require 'math'
local jac = nn.Jacobian

local RolinearTests = {}

local function generateTest(testName,mod,input) 
   RolinearTests[testName] = function()
      mod:debug() -- use debug mode so that rp is never used
      print(mod)
      local f = jac.forward(mod,input)
      local b = jac.backward(mod,input)
      local fW = jac.forward(mod,input,mod.weight)
      local bW = jac.backward(mod,input,mod.weight,mod.gradWeight)
      local fB = jac.forward(mod,input,mod.bias)
      local bB = jac.backward(mod,input,mod.bias,mod.gradBias)
      
      local errIn = (b-f):abs():max()
      local errW = (bW-fW):abs():max()
      local errB = (bB-fB):abs():max()
      print(string.format('error input is %f',errIn))
      print(string.format('error weight is %f',errW))
      print(string.format('error bias is %f',errB))
      
      local errCode = errPrint('dv_input',errIn,f,b) +
	 errPrint('dv_W',errW,fW,bW) +
	 errPrint('dv_b',errB,fB,bB)
      
      return errCode,mod
   end
end

function errPrint(errName,err,f,b,tolerence)
   tolerence = tolerence or 1e-6
   if err > tolerence then
      print(errName .. ' is wrong')
      print('forward output:')
      print(f)
      print('backward output:')
      print(b)
      return 1 -- report error
   end
   return 0 -- no error
end

function runRolinearTests()
   local passed = 0
   local count = 0
   for k,v in pairs(RolinearTests) do
      print('test ' .. k)
      local err = v()
      passed = passed + (err==0 and 1 or 0)
      print('')
      count = count + 1
   end
   print(string.format('passed %d/%d tests',passed,count))
end

------------ test generation
generateTest('[Rolinear]noRotationTest',
	     nn.Rolinear(8,3,2,1,2,2), -- inputSize,outputSize,nInputFilter,nInputAng,kH,kW,rp
	     torch.range(1,1*2*1*2*2):view(1,8) -- input: [batch_size] x inputSize 
)
generateTest('[Rolinear]BatchNonCircTest',
	     nn.Rolinear(8,3,2,1,2,2), -- inputSize,outputSize,nInputFilter,nInputAng,kH,kW,rp
	     torch.range(1,3*2*1*2*2):view(3,8) -- input: [batch_size] x inputSize 
)
generateTest('[Rolinear]nonBatchNonCircTest',
	     nn.Rolinear(8,4,2,1,2,2), -- inputSize,outputSize,nInputFilter,nInputAng,kH,kW,rp
	     torch.range(1,1*2*1*2*2):view(8) -- input: [batch_size] x inputSize 
)
generateTest('[Rolinear]BatchCircTest',
	     nn.Rolinear(16,5,2,2,2,2), -- inputSize,outputSize,nInputFilter,nInputAng,kH,kW,rp
	     torch.range(1,3*2*2*2*2):view(3,16) -- input: [batch_size] x inputSize 
)
generateTest('[Rolinear]nonBatchCircTest',
	     nn.Rolinear(16,4,2,2,2,2), -- inputSize,outputSize,nInputFilter,nInputAng,kH,kW,rp
	     torch.range(1,2*2*2*2):view(16) -- input: [batch_size] x inputSize 
)
------------ run tests
runRolinearTests()


