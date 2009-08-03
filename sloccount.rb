module Sloccount
  include Extension
  
  def sloccount
    @sloccount_config ||= SloccountConfig.new(self)
  end

  first_time do
    # Define task not specific to any projet.
    Project.local_task('sloccount')
  end

  before_define do |project|
    # Define the loc task for this particular project.
    desc 'Count lines of code in current project using sloccount'
    Rake::Task.define_task 'sloccount' do |task|
      srcdirs = task.prerequisites.join(" ")
      data_dir =  project.sloccount.data_dir
      report_to = project.sloccount.report_to
      mkdir_p data_dir.to_s
      mkdir_p File.dirname(report_to)
      puts "Creating sloccount report from dirs: #{srcdirs}"
      system "sloccount --datadir #{data_dir} --wide --details --duplicates #{srcdirs} > #{report_to} 2>&1"
      puts "Wrote sloccount report to #{report_to}"
      
      #puts "Project #{project.name} has #{lines} lines of code"
    end
  end

  after_define do |project|
    # Now that we know all the source directories, add them.
    task('sloccount'=>project.compile.sources + project.test.sources)
  end

  # To use this method in your project:
  #   loc path_1, path_2
  def loc(*paths)
    task('sloccount'=>paths)
  end


  class SloccountConfig # :nodoc:
  
    def initialize(project)
      @project = project
    end

    attr_reader :data_dir
    attr_writer :data_dir

    attr_reader :report_to
    attr_writer :report_to
    
    attr_reader :project
    private :project

    # :call-seq:
    #   project.sloccount.data_dir(dir)
    #
    def data_dir(*dir)
      if dir.empty?
        @data_dir ||= project.path_to(:reports, 'sloccount', 'data')
      else
        raise "Invalid data dir '#{dir.join(', ')}" unless dir.size == 1
        @data_dir = dir[0]
        self
      end
    end

    # :call-seq:
    #   project.sloccount.report_to(file)
    #
    def report_to(*file)
      if file.empty?
        @report_to ||= project.path_to(:reports, 'sloccount', 'report.sc')
      else
        raise "Invalid report file '#{file.join(', ')}" unless file.size == 1
        @report_to = dir[0]
        self
      end
    end
    
  end

end

class Buildr::Project
  include Sloccount
end
