require 'ruby-prof'

class Profiler

  def self.block
    RubyProf.start
    
    yield
  
    results = RubyProf.stop
 
    File.open "#{RAILS_ROOT}/tmp/profile-graph.html", 'w' do |file|
      RubyProf::GraphHtmlPrinter.new(results).print(file)
    end

    File.open "#{RAILS_ROOT}/tmp/profile-flat.txt", 'w' do |file|
      RubyProf::FlatPrinter.new(results).print(file)
    end

    File.open "#{RAILS_ROOT}/tmp/profile-tree.prof", 'w' do |file|
      RubyProf::CallTreePrinter.new(results).print(file)
    end
  end

end
