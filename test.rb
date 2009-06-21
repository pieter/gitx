class Obj
  attr_accessor :hash, :parents, :included, :date

  def initialize(hash, *parents)
    @date = 0
    @hash = hash
    @parents = parents
    @included = false
  end

  def to_line
    [@hash, @parents].flatten.join(" ")
  end
end

objs = File.read("a").split("\n").map { |l| Obj.new(*l.split(" ")) }

@obj_map = {}
objs.each { |x| @obj_map[x.hash] = x }
included_hashes = []

File.read("c").split("\n").each do |line|
  hash, date = *line.split(" ")
  included_hashes << hash
  @obj_map[hash].date = date.to_i
end

included_hashes.each { |x| @obj_map[x].included = true }
included_objects = objs.each { |x| x.included == true }

# Rewrite parents to commits that are included in the DAG
# See revision.c in git.git
included_objects.each do |obj|
  parents = obj.parents.clone
  new_parents = []
  while parents.size > 0 do
    parent = parents.shift

    if @obj_map[parent].included
      new_parents << parent
    else
      @obj_map[parent].parents.each { |x| parents << x } # This might be null
    end
  end

  obj.parents = new_parents.uniq
end

# get_bases(one, twos):
#   *markeer alle ones als ones, alle two's als two's
#   * doe alles in lijst
#   * als one, make alle parents one
#   * als two, maak alle parenst two
#   * als beide, dan voeg toe als merge base, maak alle parents stale

P1 = 1
P2 = 2
STALE = 4
RESULT = 8

def get_bases1(one, twos)
  
  # Easy check
  twos.each do |x|
    if one == x
      return [one]
    end
  end

  map = Hash.new(0)
  map[one] = P1
  twos.each { |x| map[x] = P2 }

  new_parents = []
  list = [one, twos].flatten
  list = list.select { |x| map[x] & STALE == 0 }

  while list.size > 0 do
    obj = list.shift
    flags = map[obj] & (P1 | P2 | STALE)
    if flags == (P1 | P2)
      if (flags & RESULT) == 0
        map[obj] = flags | RESULT
        new_parents << obj
      end
      flags = flags | STALE
    end
    parents = @obj_map[obj] && @obj_map[obj].parents || []
    parents.each do |p|
      next if (map[p] & flags) == flags
      map[p] = map[p] | flags
      list << p
    end
    list = list.select { |x| (map[x] & STALE) == 0 }
  end

  new_parents.uniq
end

def get_bases(one, twos)
  parents = get_bases1(one, twos)
  if parents.size <= 1
    return parents.clone
  end

  # p [one, twos].flatten
  # puts "returning:"
  # p new_parents

  #   * als meer dan een base:
  #   * doe hetzelfde voor elke combinatie van bases, en return die lijst.
  #     * check lijst met huidige bij elke combinatie, als die een van beide is, dan die twee weghalen uit mogelijkheden
  new_parents = parents.clone
  (0).upto(new_parents.size - 2) do |p1|
    (p1 + 1).upto(new_parents.size - 1) do |p2|
      next if !new_parents[p1] || !new_parents[p2]
      these_parents = get_bases1(new_parents[p1], [new_parents[p2]])
      these_parents.each do |x|
        new_parents[p1] = nil if new_parents[p1] == x
        new_parents[p2] = nil if new_parents[p2] == x
      end
    end
  end

  return new_parents.compact.uniq
end

# Now, do the merge base stuff. This is the "Reduce heads" in commit.c
included_objects.each do |obj|
  # if (more than one parent)
  #   reduce_heads(parent) <<== commit.c Only keeps one:
  #     for (parent in parents)
  #       other = previous_parents
  #       bases = get_base(parent, other)
  #       if (![bases count] || bases[0] == parent)
  #         keep_parent
  # 
  #
  
  next if obj.parents.size <= 1

  parents = obj.parents.clone
  new_parents = []
  0.upto(parents.size) do |i|
    cur_parent = parents[i]
    next if new_parents.include? cur_parent

    if i > 0
      others = parents[0..i - 1]
      bases = get_bases(cur_parent, others)
    else
      bases = []
    end

    if (bases.size == 0 || bases[0] != cur_parent)
      new_parents << cur_parent
    end
  end
  obj.parents = new_parents.compact
end

output = objs.select { |x| x.included }.map { |x| x.to_line }.sort.join("\n")
File.open("test.out", "w") { |f| f.puts output }