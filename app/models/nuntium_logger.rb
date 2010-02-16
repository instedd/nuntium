class NuntiumLogger
  
  def self.new(path, logger_name)
    require 'log4r'
    include Log4r
    
    pf = Log4r::PatternFormatter.new(:pattern => "%d %l %m")
    
    f = File.open(path, 'a')
    f.close
    logger = Log4r::Logger.new logger_name
    logger.add Log4r::RollingFileOutputter.new("#{logger_name}_outputter", :filename => path, :maxsize => 10 * 1024 * 1024, :formatter => pf)
    logger
  end

end
