require 'spec_helper'

describe Array do
  it 'should sort an array of hashes against an array of strings' do
    a = [
      { "id" => 'c' },
      { "id" => 'a' },
      { "id" => 'b' }
    ]
    b = ['a', 'b', 'c']
    sorted = a.sort_by_arr!(b, ['id'])
    expect(sorted.collect{|c|c['id']}).to eq(b)
  end

  it 'should sort a deeply nested array of hashes against an array of strings' do
    a = [
      { "data" => { "id" => 'c' } },
      { "data" => { "id" => 'a' } },
      { "data" => { "id" => 'b' } },
    ]
    b = ['a', 'b', 'c']
    sorted = a.sort_by_arr!(b, ['data', 'id'])
    expect(sorted.collect{|c| c.dig('data', 'id') }).to eq(b)
  end
end

describe Hash do
  it 'should support the blank? method' do
    expect(Hash.new().blank?).to be_truthy
  end
end

describe NilClass do
  it 'should support the blank? method' do
    expect(nil.blank?).to be_truthy
  end
end