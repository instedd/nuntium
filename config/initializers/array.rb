class Array
  def rand
    self[Kernel.rand self.length]
  end
end
