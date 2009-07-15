require 'buildr/java'

module Buildr

  module Findbugs

    VERSION = '1.3.2'

    class << self

      def settings
        Buildr.settings.build['findbugs'] || {}
      end

      def version
        settings['version'] || VERSION
      end
      
      def dependencies
        @dependencies ||= [
          "net.sourceforge.findbugs:findbugs-ant:jar:#{version}"
=begin
          'net.sourceforge.findbugs:findbugs:jar:#{version}',
          'net.sourceforge.findbugs:bcel:jar:#{version}',
          'net.sourceforge.findbugs:coreplugin:jar:#{version}',
          'net.sourceforge.findbugs:jsr305:jar:#{version}',
          'asm:asm:jar:3.0',
          'asm:asm-analysis:jar:3.0',
          'asm:asm-commons:jar:3.0',
          'asm:asm-tree:jar:3.0',
          'asm:asm-util:jar:3.0',
          'asm:asm-xml:jar:3.0',
          'dom4j:dom4j:jar:1.3',
=end
        ]
      end

      def findbugs
        unless @findbugs
          @findbugs = FindbugsConfig.new(self)
          #@findbugs.report_dir('reports/findbugs')
          #@findbugs.output_file('reports/findbugs.data')
        end
        @findbugs
      end

      # Create text output for given config
      def create_text(config)
        info "Running findbugs with results printed to stdout"
        config.ant.findbugs :home=>config.findbugs_home,
            :output => "text",
            :debug => config.debug,
            :effort => config.effort,
            :failOnError => config.fail_on_error do
          #    puts "attributes: #{config.ant.inspect}"
          #puts "auxclasspath: #{config.aux_classpath}, #{config.aux_classpath == nil}"
          if config.aux_classpath != nil
            config.ant.auxClasspath :path => config.aux_classpath
          end
          config.ant.sourcePath :path => config.src_path
          config.ant.method_missing :class, :location => config.class_location
        end
      end

      # Create xml output for given config
      def create_xml(config)
        info "Running findbugs with results written to xml output file"
        config.ant.findbugs :home=>config.findbugs_home,
            :output => "xml",
            :outputFile => config.findbugs.output_file,
            :effort => config.effort,
            :failOnError => config.fail_on_error do
          if config.aux_classpath != nil
            config.ant.auxClasspath :path => config.aux_classpath
          end
          config.ant.sourcePath :path => config.src_path
          config.ant.method_missing :class, :location => config.class_location
        end
      end
      
=begin
    <findbugs home="${hunter.findbugs.dir}/lib/" output="text">
        <auxClasspath>
            <path refid="hunter.libs"/>
            <path refid="java-build.classpath"/>
        </auxClasspath>
        <sourcePath path="${java-build.src-dir}" />
        <class location="${java-build.classes-dir}" />
    </findbugs>
=end
      

=begin
      # Create the xml report for given config
      def create_xml(config)
        mkdir_p config.report_to.to_s
        info "Creating checkstyle xml report #{config.output_file}"
        config.ant.checkstyle :config => config.config,
          :failureProperty => config.failure_property, :failOnViolation => config.fail_on_error,
          :maxErrors => config.errors, :maxWarnings => config.warnings do
          includes, excludes = config.includes, config.excludes
          src_dirs = config.sources
          if includes.empty? && excludes.empty?
            src_dirs.each do |src_dir|
              if File.exist?(src_dir.to_s)
                config.ant.fileset :dir=>src_dir.to_s do
                  config.ant.include :name => "**/*.java"
                end
              end
            end
          else
            includes = [//] if includes.empty?
            src_dirs.each do |src_dir|
              Dir.glob(File.join(src_dir, "**/*.java")) do |src|
                src_name = src.gsub(/#{src_dir}\/?|\.java$/, '').gsub('/', '.')
                if includes.any? { |p| p === src_name } && !excludes.any? { |p| p === src_name }
                  config.ant.fileset :file => src
                end
              end
            end
          end
          config.ant.formatter :type => :xml, :tofile => config.output_file
        end
      end

      # Create the html report for given config
      def create_html(config)
        target = config.html_out
        info "Creating checkstyle html report '#{target}'"
        config.ant.xslt :in => config.output_file, :out => target,
          :style => config.style
      end
=end

      # Cleans the checkstyle created artifacts
      def clean(config)
        #rm_rf [config.report_to, config.output_file]
      end
    end

    class FindbugsConfig # :nodoc:

      def initialize(project)
        puts "FindbugsConfig initialized"
        @project = project
      end

      attr_writer :output_file
      
      attr_reader :project
      private :project

      def ant
        @ant ||= Buildr.ant('findbugs') do |ant|
          cp = Buildr.artifacts(Findbugs.dependencies).each(&:invoke).map(&:to_s).join(File::PATH_SEPARATOR)
          ant.taskdef :name=>'findbugs', :classpath=>cp, :classname=>'edu.umd.cs.findbugs.anttask.FindBugsTask'
        end
      end

      def failure_property
        'findbugs.failure.property'
      end

      def report_to(file = nil)
        File.expand_path(File.join(*[report_dir, file.to_s].compact))
      end

      def html_out
        report_to('findbugs-report.html')
      end

=begin
      config.ant.findbugs :home=>config.findbugs_home, :output => "text", :effort => config.effort do
        config.ant.auxClasspath = config.aux_classpath
        config.ant.srcPath :path => config.src_path
        config.ant.class :location => config.class_location
      end
=end

      # :call-seq:
      #   project.findbugs.findbugs_home(dir)
      #
      def findbugs_home(*dir)
        if dir.empty?
          @findbugs_home ||= project.path_to(:findbugs)
        else
          raise "Invalid findbugs home dir '#{dir.join(', ')}" unless dir.size == 1
          @findbugs_home = dir[0]
          self
        end
      end

      # :call-seq:
      #   project.findbugs.aux_classpath(classpath)
      #
      # Valid values: min, default, or max
      #
      def effort(*effort)
        if effort.empty?
          @effort ||= "default"
        else
          raise "Invalid effort '#{effort.join(', ')}" unless effort.size == 1
          @effort = effort[0]
          self
        end
      end

      # :call-seq:
      #   project.findbugs.debug(bool)
      #
      def debug(*bool)
        if bool.empty?
          @debug ||= (Findbugs.settings['debug'] || false).to_s
        else
          raise "Invalid debug '#{bool.join(', ')}" unless bool.size == 1
          @debug = bool[0]
          self
        end
      end
      
      # :call-seq:
      #   project.findbugs.aux_classpath(classpath)
      #
      def aux_classpath(*classpath)
        if classpath.empty?
          @aux_classpath ||= project.compile.dependencies.join(File::PATH_SEPARATOR)
        else
          raise "Invalid aux classpath '#{classpath.join(', ')}" unless classpath.size == 1
          @aux_classpath = classpath[0]
          self
        end
      end

      # :call-seq:
      #   project.findbugs.src_path(*sources)
      #
      def src_path(*sources)
        if sources.empty?
          @src_path ||= project.compile.sources.join(File::PATH_SEPARATOR)
        else
          @src_path = [sources].flatten.uniq
          self
        end
      end

      # :call-seq:
      #   project.findbugs.class_location(dir)
      #
      def class_location(*dir)
        if dir.empty?
          @class_location ||= project.compile.target
        else
          raise "Invalid class location directory '#{dir.join(', ')}" unless dir.size == 1
          @class_location = dir[0]
          self
        end
      end


      # :call-seq:
      #   project.findbugs.output_file(file)
      #
      def output_file(*file)
        if file.empty?
          @output_file ||= project.path_to(:reports, 'findbugs.out')
        else
          raise "Invalid output file '#{file.join(', ')}" unless file.size == 1
          @output_file = file[0]
          self
        end
      end

      # :call-seq:
      #   project.findbugs.stylesheet(file)
      #
      def stylesheet(*file)
        if file.empty?
          @stylesheet
        else
          raise "Invalid stylesheet file '#{file.join(', ')}" unless file.size == 1
          @stylesheet = file[0]
          self
        end
      end

      # :call-seq:
      #   project.findbugs.fail_on_error(fail_on_error)
      #
      def fail_on_error(*fail_on_error)
        if fail_on_error.empty?
          @fail ||= (Findbugs.settings['failOnError'] || true).to_s
        else
          raise "Invalid config file '#{fail_on_error.join(', ')}" unless fail_on_error.size == 1
          @fail = fail_on_error[0]
          self
        end
      end

      # :call-seq:
      #   project.findbugs.include_filter(file)
      #
      def include_filter(*file)
        if file.empty?
          @include_filter
        else
          raise "Invalid include filter file '#{file.join(', ')}" unless file.size == 1
          @include_filter = file[0]
          self
        end
      end

      # :call-seq:
      #   project.findbugs.exclude_filter(file)
      #
      def exclude_filter(*file)
        if file.empty?
          @exclude_filter
        else
          raise "Invalid exclude filter file '#{file.join(', ')}" unless file.size == 1
          @exclude_filter = file[0]
          self
        end
      end
      
    end

    module FindbugsExtension # :nodoc:
      include Buildr::Extension

      def findbugs
        @findbugs_config ||= FindbugsConfig.new(self)
      end

      before_define do
        namespace 'findbugs' do
          desc "Creates a findbugs text report"
          task :text
      
          desc "Creates an findbugs xml report"
          task :xml

          desc "Creates an findbugs html report"
          task :html
        end
      end

      after_define do |project|
        findbugs = project.findbugs

        namespace 'findbugs' do
          unless project.compile.target.nil?
            # all target files and dirs as targets
            findbugs_xml = file findbugs.output_file => project.compile do
              Findbugs.create_xml(findbugs)
            end
            #findbugs_html = file findbugs.html_out => findbugs_xml do
            #  Findbugs.create_html(findbugs)
            #end
            #file findbugs.report_to => findbugs_html
            
            task :text => project.compile do
              puts "foo"
              Findbugs.create_text(findbugs)
            end
            task :xml => findbugs_xml
            #task :html => findbugs_html

            task :findbugs_lenient do
              info "Setting findbugs to ignore violations"
              project.findbugs.fail_on_error(false)
            end

            task :fail_on_error => [:findbugs_lenient, :xml] do
              property = findbugs.ant.project.properties.find { |current| current[0] == findbugs.failure_property }
              property = property.nil? ? nil : property[1]
              fail "To many findbugs errors or warnings see reports in '#{findbugs.report_to}'" if property
            end
          end

          project.clean do
            Findbugs.clean(findbugs)
          end
        end
      end
    end

    class Buildr::Project
      include FindbugsExtension
    end

=begin
    namespace "findbugs" do
      findbugs_xml = file findbugs.output_file do
        findbugs.sources(Buildr.projects.map(&:findbugs).map(&:sources).flatten)
        unless findbugs.config
          configs = Buildr.projects.map(&:findbugs).map(&:config).uniq.reject {|conf|
            conf.nil? || conf.strip.empty?
          }
          raise "Could not set findbugs config from projects, existing configs: '#{configs.join(', ')}'" if configs.size != 1
          info "Setting findbugs config to '#{configs[0]}'"
          findbugs.config(configs[0])
        end
        create_xml(findbugs)
      end
      findbugs_html = file findbugs.html_out => findbugs_xml do
        unless findbugs.style
          styles = Buildr.projects.map(&:findbugs).map(&:style).uniq.reject{|style|
            style.nil? || style.strip.empty?
          }
          raise "Could not set html style from projects, existing styles: '#{styles.join(', ')}'" if styles.size != 1
          info "Setting findbugs html style to '#{styles[0]}'"
          findbugs.style(styles[0])
        end
        create_html(findbugs)
      end
      file findbugs.report_to => findbugs_html
      
      desc "Create findbugs xml report in #{findbugs.report_to.to_s}"
      task :xml => findbugs_xml

      desc "Create findbugs html report in #{findbugs.report_to.to_s}"
      task :html =>findbugs_html
        
    end
=end

    task "clean" do
      clean(findbugs)
    end
  end
end

