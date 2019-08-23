--'Which tracks appeared in the most playlists? how many playlist did they appear in?'
WITH query AS (SELECT COUNT(*) AS count
FROM playlist_track
GROUP BY TrackId)
SELECT MAX(count)
FROM query;

WITH query AS (SELECT COUNT(*) as count,TrackId
FROM playlist_track
GROUP BY TrackId
ORDER BY 1 DESC)  
SELECT *
FROM query 
WHERE count=5;

--Which track generated the most revenue? which album? which genre?
SELECT SUM(UnitPrice*Quantity), TrackId
FROM invoice_items
GROUP BY TrackId
ORDER BY 1 DESC;

WITH query AS (SELECT SUM(UnitPrice*Quantity) AS revenue, TrackId
FROM invoice_items
GROUP BY TrackId
ORDER BY revenue DESC
)
SELECT  tracks.GenreId,query.revenue,tracks.TrackId,
tracks.AlbumId,albums.Title,genres.Name
FROM tracks
JOIN query ON query.TrackId=tracks.TrackId
JOIN albums ON albums.AlbumId=tracks.AlbumId
JOIN genres ON genres.GenreId=tracks.GenreId;

--Which countries have the highest sales revenue? What percent of total revenue does each country make up?
WITH query AS (select SUM(UnitPrice*Quantity) AS revenue, TrackId
FROM invoice_items
GROUP BY TrackId
ORDER BY revenue DESC
)
SELECT  SUM(query.revenue),invoices.BillingCountry
FROM tracks
LEFT JOIN query ON query.TrackId=tracks.TrackId
LEFT JOIN invoice_items ON tracks.TrackId=invoice_items.TrackId
LEFT JOIN invoices ON invoices.InvoiceId=invoice_items.InvoiceId ;

 WITH query AS (SELECT SUM(UnitPrice*Quantity) AS revenue, TrackId
FROM invoice_items
GROUP BY TrackId
ORDER BY revenue DESC
)
SELECT  100*SUM(query.revenue)/(SELECT SUM(query.revenue) FROM query ),invoices.BillingCountry
FROM tracks
LEFT JOIN query on query.TrackId=tracks.TrackId
LEFT JOIN invoice_items on tracks.TrackId=invoice_items.TrackId
LEFT JOIN invoices on invoices.InvoiceId=invoice_items.InvoiceId
GROUP BY BillingCountry
ORDER BY 1 DESC;

--How many customers did each employee support, what is the average revenue for each sale, and what is their total sale?
SELECT COUNT(*),EmployeeId
FROM customers
JOIN employees ON customers.SupportRepId=employees.EmployeeId
GROUP BY EmployeeId;

SELECT AVG(Quantity*UnitPrice), InvoiceId
FROM invoice_items
GROUP BY InvoiceId;

SELECT SUM(UnitPrice*Quantity), customers.SupportRepId
FROM invoice_items
LEFT JOIN invoices ON invoices.InvoiceId=invoice_items.InvoiceId
LEFT JOIN customers ON customers.CustomerId=invoices.CustomerId
GROUP BY SupportRepId;

SELECT SUM(UnitPrice), customers.SupportRepId,customers.CustomerId,invoice_items.UnitPrice,
invoices.InvoiceId, invoice_items.Quantity,invoice_items.TrackId
FROM invoice_items
LEFT JOIN invoices ON invoices.InvoiceId=invoice_items.InvoiceId
LEFT JOIN customers ON customers.CustomerId=invoices.CustomerId
GROUP BY SupportRepId;

--Do longer or shorter length albums tend to generate more revenue?

WITH query AS (SELECT SUM(invoice_items.UnitPrice*invoice_items.Quantity) AS revenue, tracks.AlbumId
FROM invoice_items
JOIN tracks ON tracks.TrackId=invoice_items.TrackId
GROUP BY tracks.AlbumId
),
 query2 AS (SELECT count(*) AS album_length, albums.AlbumId
FROM albums
JOIN tracks on albums.AlbumId=tracks.AlbumId
GROUP BY albums.AlbumId 
)
SELECT  query.AlbumId, query.revenue, query2.album_length
FROM query
JOIN query2 ON query.AlbumId=query2.AlbumId
ORDER BY revenue DESC;
/*Revenue and album_length has a positive correlation of 0.817129988441762 suggesting longer albums 
tend to generate more revenue, you can also see the scatter plot in the excel file with name "corr.ods"  */

--Is the number of times a track appear in any playlist a good indicator of sales?
WITH query AS (SELECT SUM(UnitPrice*Quantity) AS revenue, TrackId
FROM invoice_items
GROUP BY TrackId),
query2 AS (SELECT COUNT(*) AS playlist_count,tracks.TrackId
FROM tracks
JOIN playlist_track ON tracks.TrackId =playlist_track.TrackId
GROUP BY tracks.TrackId)
SELECT AVG(revenue) ,query2.playlist_count
FROM query 
JOIN query2 ON query.TrackId=query2.TrackId
GROUP BY playlist_count;
-- No, tracks with different playlist_counts has approximately same avarage value.

--How much revenue is generated each year, and what is its percent change from the previous year?
WITH prev_year_query AS (
WITH query AS (SELECT strftime('%Y',InvoiceDate) AS year, invoices.InvoiceId 
FROM invoices )
SELECT  query.year AS prev_year , SUM(UnitPrice*Quantity) AS prev_year_revenue
FROM invoice_items 
JOIN invoices ON invoices.InvoiceId =invoice_items.InvoiceId
JOIN query ON query.InvoiceId=invoices.InvoiceId
GROUP BY year
HAVING year!='2013')WITH prev_year_query AS (
WITH query AS (SELECT strftime('%Y',InvoiceDate) AS year, invoices.InvoiceId 
FROM invoices )
SELECT  query.year AS prev_year , SUM(UnitPrice*Quantity) AS prev_year_revenue
FROM invoice_items 
JOIN invoices ON invoices.InvoiceId =invoice_items.InvoiceId
JOIN query ON query.InvoiceId=invoices.InvoiceId
GROUP BY year
HAVING year!='2013')
, current_year_query AS( 
WITH query AS (SELECT strftime('%Y',InvoiceDate) AS year, invoices.InvoiceId 
FROM invoices )
SELECT  query.year AS current_year , SUM(UnitPrice*Quantity) AS current_year_revenue
FROM invoice_items 
JOIN invoices ON invoices.InvoiceId =invoice_items.InvoiceId
JOIN query ON query.InvoiceId=invoices.InvoiceId
GROUP BY year)
SELECT ((current_year_revenue-prev_year_revenue)/prev_year_revenue)*100 AS percent_change, 
current_year AS year, current_year_revenue AS revenue
FROM prev_year_query
CROSS JOIN current_year_query
WHERE CAST(prev_year AS INTEGER)=(CAST(current_year AS INTEGER)-1);

, current_year_query AS( 
WITH query AS (SELECT strftime('%Y',InvoiceDate) AS year, invoices.InvoiceId 
FROM invoices )
SELECT  query.year AS current_year , SUM(UnitPrice*Quantity) AS current_year_revenue
FROM invoice_items 
JOIN invoices ON invoices.InvoiceId =invoice_items.InvoiceId
JOIN query ON query.InvoiceId=invoices.InvoiceId
GROUP BY year)
SELECT ((current_year_revenue-prev_year_revenue)/prev_year_revenue)*100 AS percent_change, 
current_year AS year, current_year_revenue AS revenue
FROM prev_year_query
CROSS JOIN current_year_query
WHERE CAST(prev_year AS INTEGER)=(CAST(current_year AS INTEGER)-1);
