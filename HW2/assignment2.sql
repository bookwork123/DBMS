-- 1. Average Price of Foods at Each Restaurant
select restaurants.name as restaurant, avg(foods.price) AS avg_price
from restaurants
join serves on restaurants.restID = serves.restID
join foods on serves.foodID = foods.foodID
group by restaurants.name;

-- 2. Maximum Food Price at Each Restaurant
select restaurants.name as restaurant, max(foods.price) as max_price
from restaurants
join serves on restaurants.restID = serves.restID
join foods on serves.foodID = foods.foodID
group by restaurants.name;

-- 3. Count of Different Food Types Served at Each Restaurant
select restaurants.name as restaurant, count(foods.foodID) as amt_of_foods
from restaurants
join serves on restaurants.restID = serves.restID
join foods on serves.foodID = foods.foodID
group by restaurants.name;

-- 4. Average Price of Foods Served by Each Chef
select chefs.name as chef, avg(foods.price) as avg_price
from chefs
join foods on chefs.specialty = foods.type
group by chefs.name;

-- 5. Find the Restaurant with the Highest Average Food Price
select restaurants.name as restaurant, avg(foods.price) AS avg_price
from restaurants
join serves on restaurants.restID = serves.restID
join foods on serves.foodID = foods.foodID
group by restaurants.name
order by avg_price desc
limit 1;

-- 6 Extra Credit
-- Determine which chef has the highest average price of the foods served at the 
-- restaurants where they work. Include the chef’s name, the average food price, 
-- and the names of the restaurants where the chef works. 
-- Sort the  results by the average food price in descending order.
select chefs.name, avg(foods.price) as avg_price, restaurants.name, group_concat(distinct restaurants.name order by restaurants.name) as restaurants
from chefs
join works on chefs.chefID = works.chefID
join restaurants on works.restID = restaurants.restID
join serves on restaurants.restID = serves.restID
join foods on serves.foodID = foods.foodID
group by chefs.chefID, chefs.name, restaurants.name
order by avg(foods.price) desc
limit 1;