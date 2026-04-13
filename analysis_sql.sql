CREATE TABLE ecommerce_events (
	event_time TIMESTAMP,
	event_type VARCHAR(20),
	product_id BIGINT,
	category_id BIGINT,
	category_code TEXT,
	brand Text,
	price NUMERIC,
	user_id BIGINT,
	user_session TEXT
);

SELECT * FROM ecommerce_events LIMIT 10;

SELECT COUNT(*) FROM ecommerce_events;

SELECT
	event_type,
	COUNT(*) AS events,
	ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (), 2) AS percentage
From ecommerce_events
group by event_type
order by events desc;

Select
	Date(event_time) AS event_date,
	Count(*) AS total_events
From ecommerce_events
Group by event_date
Order by event_date;

Select
	category_code,
	Count(*) AS total_events
From ecommerce_events
Where category_code is not null
Group by category_code
Order by total_events desc
Limit 10;

Select Distinct event_type From ecommerce_events;

Alter table ecommerce_events
Rename column use_session to user_session;

Delete from ecommerce_events
Where user_session is Null or user_id is Null;

Update ecommerce_events
Set category_code = 'unknown'
Where category_code is Null;

Create Index idx_user_session on ecommerce_events(user_session);
Create Index idx_event_type on ecommerce_events(event_type);
Create Index idx_event_time on ecommerce_events(event_time);

Create table funnel as
Select
	user_session, 
	user_id,
	Min(event_time) as session_start,
	Max(event_time) as session_end,
	Max(Case when event_type='view' Then 1 Else 0 End) As view_only,
	Max(Case when event_type='cart' Then 1 Else 0 End) As added_to_cart,
	Max(Case when event_type='purchase' Then 1 Else 0 End) As purchased,
	Count(*) as total_events,
	Sum(Case When event_type='purchase' Then price Else 0 End) As revenue
From ecommerce_events
Group by user_session, user_id;

Select * From funnel Limit 10;

Select Count(*) From funnel;

Select
	Count(*) as total_session,
	Sum(view_only) as viewed_sessions,
	Sum(added_to_cart) as cart_sessions,
	Sum(purchased) as Purchase_sessions
From funnel;

SELECT
    COUNT(*) AS total_sessions,
    SUM(view_only) AS viewed_sessions,
    SUM(CASE WHEN view_only = 1 THEN added_to_cart ELSE 0 END) AS cart_sessions,
    SUM(CASE WHEN added_to_cart = 1 THEN purchased ELSE 0 END) AS purchase_sessions,

    ROUND(100.0 * SUM(CASE WHEN view_only = 1 THEN added_to_cart ELSE 0 END) / NULLIF(SUM(view_only), 0), 2) AS view_to_cart_rate,

    ROUND(100.0 * SUM(CASE WHEN added_to_cart = 1 THEN purchased ELSE 0 END) / NULLIF(SUM(CASE WHEN view_only = 1 THEN added_to_cart ELSE 0 END), 0), 2) AS cart_to_purchase_rate

FROM funnel;

Select
	Count(*) Filter(Where view_only=1 and added_to_cart=0) as view_then_drop,
	Count(*) Filter(Where added_to_cart=1 and purchased=0) as cart_then_drop
From funnel;

Select
	Sum(revenue) as total_revenue,
	Avg(revenue) as avg_revenue
From funnel;

Select
	user_id,
	Sum(revenue) as total_spent
From funnel
Group by user_id
Order by total_spent Desc
Limit 20;

Select
	Sum(Case When added_to_cart=1 Then 1 Else 0 End) As carted,
	Sum(Case When added_to_cart=1 And purchased=0 Then 1 Else 0 End) As cart_abandoned,
	Round(100* Sum(Case When added_to_cart=1 And purchased=0 Then 1 Else 0 End)/ Nullif(Sum(Case When added_to_cart=1 Then 1 Else 0 End),0),2) as cart_abandonment_rate
From funnel;