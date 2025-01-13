-- MIT License

-- Copyright (c) 2021 Ryan

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local Vector = {}
Vector.__index = Vector

local function newVector( x, y )
    return setmetatable( { x = x or 0, y = y or 0 }, Vector )
end

function isvector( vTbl )
    return getmetatable( vTbl ) == Vector
end

function Vector.__unm( vTbl )
    return newVector( -vTbl.x, -vTbl.y )
end

function Vector.__add( a, b )
    return newVector( a.x + b.x, a.y + b.y )
end

function Vector.__sub( a, b )
    return newVector( a.x - b.x, a.y - b.y )
end

function Vector.__mul( a, b )
    if type( a ) == "number" then
        return newVector( a * b.x, a * b.y )
    elseif type( b ) == "number" then
        return newVector( a.x * b, a.y * b )
    else
        return newVector( a.x * b.x, a.y * b.y )
    end
end

function Vector.__div( a, b )
    return newVector( a.x / b, a.y / b )
end

function Vector.__eq( a, b )
    return a.x == b.x and a.y == b.y
end

function Vector:__tostring()
    return "(" .. self.x .. ", " .. self.y .. ")"
end

function Vector:ID()
    if self._ID == nil then
        local x, y = self.x, self.y
        self._ID = 0.5 * ( ( x + y ) * ( x + y + 1 ) + y )
    end

    return self._ID
end

return setmetatable( Vector, { __call = function( _, ... ) return newVector( ... ) end } )