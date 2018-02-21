class RandomGenerator
  def self.number2
    (1..2).map { ('1'..'9').to_a.rand }.join
  end

  def self.number4
    (1..4).map { ('1'..'9').to_a.rand }.join
  end

  def self.number8
    (1..8).map { ('1'..'9').to_a.rand }.join
  end

  def self.guid
    (1..10).map { ('a'..'z').to_a.rand }.join
  end

  def self.iso2
    (1..2).map { ('a'..'z').to_a.rand }.join
  end

  def self.iso3
    (1..3).map { ('a'..'z').to_a.rand }.join
  end

  def self.phone_prefix
    (1..2).map { ('1'..'9').to_a.rand }.join
  end
end
