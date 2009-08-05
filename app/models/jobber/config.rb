class Jobber::Config
  @@locker_proc = nil
  @@scope_proc = nil
  cattr_reader :locker_proc, :scope_proc

  def self.set_locker_name(arg = nil, &block)
    @@locker_proc = arg || block
  end

  def self.set_scope(arg = nil, &block)
    @@scope_proc = arg || block
  end
end
