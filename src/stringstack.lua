-- simple string stacks for colloquy

stringStack = {
   new = function()
     return {
       add = stringStack.add,
       create = stringStack.create,
       stack = {},
     }
   end,

   add = function(self, string)
     local i;
     tinsert(self.stack, string);
     for i = self.stack.n - 1, 1, -1 do
       if (strlen(self.stack[i]) > strlen(self.stack[i + 1])) then break end;
       self.stack[i] = self.stack[i] .. tremove(self.stack);
     end;
   end,

   create = function(self)
     local i;
     for i = self.stack.n - 1, 1, -1 do
       self.stack[i] = self.stack[i] .. tremove(self.stack);
     end;
     return self.stack[1];
   end,

};
