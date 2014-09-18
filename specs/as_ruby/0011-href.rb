

describe :href do

  it "produces 'a' elements with 'href'" do
    target '<a href="&#47;here">Here</a>'

    actual do
      a.href('/here') { "Here" }
    end
  end

end # === describe :href
