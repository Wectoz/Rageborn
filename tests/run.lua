-- lua5.1 tests/run.lua : runs every tests/test_*.lua. Each returns a list of { name, fn }.
dofile("tests/stub.lua")
local failed, count = {}, 0
local p = io.popen("ls tests/test_*.lua 2>/dev/null")
for file in p:lines() do
    local ok, tests = pcall(dofile, file)
    if not ok then
        failed[#failed + 1] = file .. ": " .. tostring(tests)
    else
        for _, t in ipairs(tests) do
            count = count + 1
            local good, err = pcall(t[2])
            if not good then failed[#failed + 1] = file .. " / " .. t[1] .. ": " .. tostring(err) end
        end
    end
end
p:close()
if #failed > 0 then
    for _, f in ipairs(failed) do print("FAIL " .. f) end
    print(("%d of %d failed"):format(#failed, count))
    os.exit(1)
end
print(("ALL PASS (%d tests)"):format(count))
