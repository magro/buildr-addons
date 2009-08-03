module LinesOfCode
  include Extension

  first_time do
    # Define task not specific to any project.
    #Project.local_task('loc')
  end

  before_define do |project|
    # Define the loc task for this particular project.
    desc 'Count lines of code in current project'
    Rake::Task.define_task 'loc' do |task|
      lines = task.prerequisites.map { |path| Dir["#{path}/**/*"] }.flatten.uniq.
        inject(0) { |total, file| total + (File.directory?(file) ? 0 : File.readlines(file).size) }
      puts "Project #{project.name} has #{lines} lines of code"
    end
  end

  after_define do |project|
    # Now that we know all the source directories, add them.
    task('loc'=>project.compile.sources + project.test.sources)
  end

  # To use this method in your project:
  #   loc path_1, path_2
  def loc(*paths)
    task('loc'=>paths)
  end

end

class Buildr::Project
  include LinesOfCode
end
