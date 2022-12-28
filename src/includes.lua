return function(tbl, value)
  for i, v in pairs(tbl) do
    if v == value then
      return true
    end
  end

  return false
end