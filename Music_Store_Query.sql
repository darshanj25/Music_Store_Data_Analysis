--  Question set 1 (Easy)

-- 1. Who is the senior most employee based on job title?

SELECT title, first_name, last_name
FROM employee
ORDER BY levels DESC
LIMIT 1 

-- 2. Which countries have the most Invoices?

SELECT COUNT (billing_country) as c, billing_country
FROM invoice 
GROUP BY billing_country
ORDER BY c DESC

-- 3. What are top 3 values of total invoice?

SELECT * 
FROM invoice
ORDER BY total DESC
LIMIT 3

/* 4.Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT billing_city, sum(total) as InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 1

/* 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money. */

SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) as ITotal
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id 
GROUP BY customer.customer_id
ORDER BY ITotal DESC
LIMIT 1

--  Question set 2 (Moderate)

/* 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT email ,first_name, last_name /*, genre.name*/
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;

/* 2. Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT artist.artist_id, artist.name, count(artist.artist_id) AS TrackCount
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY TrackCount DESC 
LIMIT 10

/* 3. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) AS avg_track_length
					FROM track)
ORDER BY milliseconds DESC

--  Question set 3 (Advance)

/* 1. Find how much amount spent by each customer on artists? Write a query to return customer name, 
artist name and total spent */

SELECT c.First_Name || ' ' || c.Last_Name AS "Customer Name",
       ar.Name AS "Artist Name",
       SUM(il.Unit_Price * il.Quantity) AS "Total Spent"
FROM customer c
JOIN invoice i ON c.Customer_Id = i.Customer_Id
JOIN invoice_line il ON i.Invoice_Id = il.Invoice_Id
JOIN track t ON il.Track_Id = t.Track_Id
JOIN album al ON t.Album_Id = al.Album_Id
JOIN artist ar ON al.Artist_Id = ar.Artist_Id
GROUP BY c.Customer_Id, ar.Artist_Id
ORDER BY "Total Spent" DESC, "Customer Name", "Artist Name";

/* 2. We want to find out the most popular music Genre for each country. We determine the most popular 
genre as the genre with the highest amount of purchases. Write a query that returns each country along 
with the top Genre. For countries where the maximum number of purchases is shared return all Genres. */

/* Method 1 */

SELECT 
    c.country, 
    t.genre_id,
	g.name,
    SUM(il.quantity) AS total_purchases
FROM 
    invoice i 
    JOIN customer c ON i.customer_id = c.customer_id 
    JOIN invoice_line il ON i.invoice_id = il.invoice_id 
    JOIN track t ON il.track_id = t.track_id
	JOIN genre g ON t.genre_id = g.genre_id
GROUP BY 
    c.country, 
    t.genre_id,
	g.name
HAVING 
    SUM(il.quantity) = (
        SELECT 
            MAX(total_purchases) 
        FROM 
            (SELECT 
                c2.country, 
                t2.genre_id, 
                SUM(il2.quantity) AS total_purchases 
            FROM 
                invoice i2 
                JOIN customer c2 ON i2.customer_id = c2.customer_id 
                JOIN invoice_line il2 ON i2.invoice_id = il2.invoice_id 
                JOIN track t2 ON il2.track_id = t2.track_id 
            GROUP BY 
                c2.country, 
                t2.genre_id) 
            AS country_genre_totals 
        WHERE 
            c.country = country_genre_totals.country)
ORDER BY  
    total_purchases DESC,
	c.country;


WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

/* Method 2 */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1
