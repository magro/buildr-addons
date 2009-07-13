# $Id$
# (c) Copyright 2009 freiheit.com technologies GmbH
#
# This file contains unpublished, proprietary trade secret information of
# freiheit.com technologies GmbH. Use, transcription, duplication and
# modification are strictly prohibited without prior written consent of
# freiheit.com technologies GmbH.
require 'buildr/java'

module CheckstyleAnt include Buildr::Extension

  first_time do
    # Define task not specific to any projet.
    desc 'Check code conventions for all projects'
    Project.local_task 'checkstyle'
  end

  before_define do |project|
    project.recursive_task('checkstyle')
  end


  after_define do |project|
    #checkstyle = project.task('checkstyle')
    javaDir = project._('src/main/java')
    if File.exists?(javaDir) && File.directory?(javaDir)
      # Define the loc task for this particular project.
      
      task :checkstyle do |task|
      
        puts "-----------------------------------------------------------"
        puts "Running checkstyle for project #{project.name}"
        puts "-----------------------------------------------------------"
        
        Buildr.ant('checkstyle') do |ant|
            
          ant.taskdef :name=>'checkstyle', :classname=>'com.puppycrawl.tools.checkstyle.CheckStyleTask',\
          :classpath=>FileList[ 'etc/build-support/checkstyle/*.jar' ].join( File::PATH_SEPARATOR )
      
          ant.checkstyle :config=>'etc/code-conventions/checkstyle_checks.xml', :failOnViolation=>'true', :maxWarnings=>0 do
            #ant.formatter :type=>'xml', :tofile=>project._('target/checkstyle_report.xml')
            ant.fileset :dir=>javaDir, :includes=>'**/*.java'
          end
          
          #ant.xslt :in=>project._('target/checkstyle_report.xml'), :out=>project._('target/checkstyle_report.html'), :style=>'etc/code-conventions/checkstyle.xsl'
      
        end
        
      end
    end
  end

  def checkstyle()
    task('checkstyle')
  end

end

class Buildr::Project
  include CheckstyleAnt
end
