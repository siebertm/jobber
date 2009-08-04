class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobber_jobs do |t|
      t.integer  :priority, :default => 0
      t.integer  :attempts, :default => 0
      t.string   :type
      t.text     :data

      t.datetime :run_at
      t.datetime :locked_at
      t.string   :locked_by

      t.timestamps
    end
  end

  def self.down
    drop_table :jobber_jobs
  end
end
