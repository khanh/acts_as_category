namespace :categories do
  desc "Build the counter caches used by Acts As Category (children_count, ancestors_count, descendants_count)"
  task :import => :environment do
    #Update the children_count column
    Category.find(:all).each do |cat|
      puts "Running child cache update for #{cat.name}"
      new_children_count = 0
      Category.uncached do
        new_children_count = Category.count(:conditions => {:parent_id => cat.id})
      end
      if new_children_count > 0 && cat.children_count != new_children_count
        puts "Needed update.... #{cat.children_count || 0} to #{new_children_count}"
        cat.class.connection.execute "UPDATE #{cat.class.table_name} SET children_count=#{new_children_count} WHERE id=#{cat.id}"
      end
    end
    Category.find(:all, :conditions => {:parent_id => nil}).each do |cat|
      puts "Running branch cache update for #{cat.name} (could be slow for large trees)"
      Category.refresh_cache_of_branch_with(cat)
    end
  end
end
