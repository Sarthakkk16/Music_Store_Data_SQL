Select * from album
/* Set-1 (Easy)*/
/* Q1 Who is the senior most employee based on job title?*/

select * from employee
order by levels desc 
limit 1

/* Q2.Which countries have the most Invoices?*/

select count(*) as c, billing_country
from Invoice
group by billing_country /* for count number*/
order by c desc

/* Q3. What are top 3 values of total Invoice*/

select billing_country, total from Invoice
order by total desc
limit 3

/* Q4. Which city has the best customers? We would like to throw a promotional 
Music Festival in the city we made the most money.
Write a query that returns one city that has the highest sum of invoice totals
Return both the city name & sum of all invoice totals. */

select sum(total) as invoice_total, billing_city
from Invoice
group by billing_city
order by invoice_total desc
limit 1

/* Q5. Who is the best customer? The customer who has 
spent the most money will be declared the best customer
Write a query that returns the person who has spent the most money*/

select customer.customer_id, customer.first_name, customer.last_name
, sum(invoice.total) as total
from customer
join invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total desc
limit 1

/* Set - 2 */

/* Q1. Write query to return the email, first_name
last_name, & Genre of all Rock Music llisteners. Return your list ordered alphabetically 
by email starting with A */

select distinct email, first_name, last_name, g.name 
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
join track on invoice_line.track_id = track.track_id
join genre g on track.genre_id = g.genre_id
where g.name Like 'Rock'
order by email;

/* Q2. let's invite the artist who have written the
most rock music in our dataset. Write a query that 
returns the Artist name and total track count of the 
top 10 rock bands.*/

select artist.artist_id, artist.name, count(artist.artist_id)
as number_of_songs
from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
Where genre.name Like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10;

/* Return all the track names that have a 
song length longer than the average song 
length. Return the Name and Milliseconds 
for each track. Order by the song length 
with the longest songs listed first*/

select * from track

select name, milliseconds
from track
Where milliseconds > (
	select avg(milliseconds) as  avg_track_legth
	from track)
order by milliseconds desc;
)

/* Set - 3 */

/* Q1. Find how much amount spent by each customer on artists?
Write a query to return customer name, artist name and 
total spent */

With best_selling_artist as(
	select artist.artist_id as artist_id, artist.name as artist_name, 
	sum(invoice_line.unit_price * invoice_line.quantity) as total_sales
	from invoice_line
	join track on track.track_id = invoice_line.track_id
	join album on album.album_id = track.album_id
	join artist on artist.artist_id = album.artist_id
	group by 1
	order by 3 desc
	limit 1
)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
sum(il.unit_price*quantity) as amount_sales
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album a on a.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = a.artist_id
group by 1,2,3,4 /* cust_id, first_name, l_name, arti_name */
order by 5 desc;

/* Q2. We want to find out the most popular music Genre for 
each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns 
each country along with the top Genre. For countries where the 
maximum number of purchases is shared return all Genres.*/


with popular_genre as
(
	select count(il.quantity) as purchases, 
	c.country, g.name, g.genre_id,
	row_number() over(partition by c.country 
	order by count(il.quantity) desc) as RowNo
	from invoice_line il
	join invoice i on i.invoice_id = il.invoice_id
	join customer c on c.customer_id = i.customer_id
	join track t on t.track_id = il.track_id
	join genre g on g.genre_id = t.genre_id
	group by 2,3,4
	order by 2 asc, 1 desc
) 
select * from popular_genre where RowNo <=1

--Method 2

with recursive
		sales_per_country as(
			select count(*) purchases_per_genre, c.country, g.name,
			g.genre_id
			from invoice_line il
			join invoice i on i.invoice_id = il.invoice_id
			join customer c on c.customer_id = i.customer_id
			join track t on t.track_id = il.track_id
			join genre g on g.genre_id = t.genre_id
			group by 2,3,4
			order by 2
		),
		max_genre_per_country as (select max(purchases_per_genre)
		as max_genre_number, country
		from sales_per_country
		group by 2
		order by 2)

select sales_per_country.*
from sales_per_country
join max_genre_per_country on sales_per_country.country = 
max_genre_per_country.country
where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number
		

/* Q3. write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

with recursive
		customer_with_country as (
			select c.customer_id, first_name, last_name, billing_country,
			sum(total) as total_spending
			from invoice i
			join customer c on c.customer_id = i.customer_id
			group by 1,2,3,4
			order by 2,3 desc),

		country_max_spending as(
			select billing_country, max(total_spending) as max_spending
			from customer_with_country
			group by billing_country)
			
select cc.billing_country, cc.total_spending , cc.first_name, cc.last_name, cc.customer_id
from customer_with_country cc
join country_max_spending ms
on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
order by 1;

--Method 2

with customer_with_country as (
		select c.customer_id, first_name, last_name, billing_country,
		sum(total) as total_spending, row_number()
		over(partition by billing_country order by sum(total) desc) 
		as RowNo
		from invoice i
		join customer c on c.customer_id = i.customer_id
		group by 1,2,3,4
		order by 4 asc, 5 desc)
select * from customer_with_country where RowNo <=1
)