module MfluxHelpers
  def java_memory_model()
    version = `java -version 2>&1`
    if /64-Bit/.match(version) then '64' else '32' end
  end

  def java_memory_max(arg) 
    if arg && arg != '' then
      max = arg.to_i
      if max < 128 then
        raise 'The JVM max memory size is too small'
      end
    else
      # Intuit a sensible max size from the platform and the available memory.
      if java_memory_model() == '32' then
        max = if node.platform?("windows") then 1500 else 2048 end
      else
        max = (/([0-9]+)kB/.match(node['memory']['total'])[1].to_i / 1024) - 512
        if max > 4096 then
          # Giving the JVM too much memory is likely to lead to poor performance
          # if memory has been over-allocated, and/or if the JVM needs to do
          # a full GC.  
          max = 4096
        end
      end
    end
    return max
  end

  def fillIn(arg, default) 
    ( if arg && arg != '' then arg else default end )
  end
end
