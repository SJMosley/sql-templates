# Retention query examples

Though I have tracked retention and growth in the past, those databases were proprietary.

This example is based on [How Duolingo Reignited User Growth](https://www.lennysnewsletter.com/p/how-duolingo-reignited-user-growth). The data model is my own construct and it would need to be adapted and tested against a real database, I attempted to keep it consistent throughout the examples.

## Usage
You can generate the data by running the `generate_user_engagements.py` script in the folder. You can edit the file to say how many users you want to generate. Or you can use the events_data.csv file and import that into your test DB, though the users were generated on 2024-02-23 so the query may not work the way you expect.

## Queries
- **retention_current:** this query will give you all the metrics for the current point in time.
- **retention_history:** this query will give you all the metrics for the past 60 days. It is probably not a great idea to run this as it could take a while with the date cross join. It would probably be best to run the current query on a cron job and save the results to a table.

### DAU
- **New users (NURR):** first day of engagement ever in the app
- **Current users (CURR):** engaged today and at least one other time in the prior 6 days
- **Reactivated users (RURR):** first day of engagement after being away for 7-29 days
- **Resurrected users (SURR):** first day of engagement after being away for 30 days or longer

### Not Active Today (yet 😬)
- **At-risk WAU:** inactive today, but active in at least one of the prior 6 days 
- **WAU** = At-risk WAU + DAU
- **At-risk MAU:** inactive in the past seven days, but active in at least one of the prior 29* days
- **MAU** = At-risk MAU + WAU
- **Dormant users:** inactive in the past 30* days or longer 
- **Total user base** = MAU + dormant users

*Numbers were edited to make the total user base correct. Leaving gaps would produce an incorrect result.