from datetime import datetime, timedelta
import random
import csv  # Import the csv module

# File path for the CSV
csv_file_path = './events_data.csv'

# Constants
NUM_USERS = 2000  # Total number of users to distribute across buckets
START_DATE = datetime.now().date()  # Assuming this script is run on the current date
END_DATE = START_DATE - timedelta(days=60)  # Data generation going back 60 days
START_ID = 1
# Generate unique user IDs
user_ids = [f"user_{i}" for i in range(START_ID, START_ID + NUM_USERS + 1)]

# Function to generate random dates within a range
def generate_dates(start_date, end_date, num_dates):
    delta = start_date - end_date
    return [end_date + timedelta(days=random.randint(0, delta.days)) for _ in range(num_dates)]

# Initial empty list to store event data
events_data = []

# Function to assign users to buckets
def assign_to_buckets(user_ids, start_date, end_date):
    for user_id in user_ids:
        # Determine the bucket for the user
        bucket_choice = random.choice([
            'nurr', 'curr', 'rurr', 'surr', 'risk_wau', 'risk_mau', 'dormant'
        ])

        if bucket_choice == 'nurr':
            # New users with only one engagement date
            max_date = start_date
            events_data.append((user_id, max_date))
        elif bucket_choice == 'curr':
            # Current users who engaged today and within the last 6 days
            max_date = start_date
            previous_date = start_date - timedelta(days=random.randint(1, 6))
            events_data.extend([(user_id, max_date), (user_id, previous_date)])
        elif bucket_choice == 'rurr':
            # Returning users who engaged today and between 7 and 29 days ago
            max_date = start_date
            previous_date = start_date - timedelta(days=random.randint(7, 29))
            events_data.extend([(user_id, max_date), (user_id, previous_date)])
        elif bucket_choice == 'surr':
            # Sleeping users who engaged today but had their last engagement more than 30 days ago
            max_date = start_date
            previous_date = start_date - timedelta(days=random.randint(30, 60))
            events_data.extend([(user_id, max_date), (user_id, previous_date)])
        elif bucket_choice == 'risk_wau':
            # Users at risk weekly, with the last engagement between 1 and 7 days ago
            max_date = start_date - timedelta(days=random.randint(1, 7))
            previous_date = max_date - timedelta(days=random.randint(1, 10))
            events_data.extend([(user_id, max_date), (user_id, previous_date)])
        elif bucket_choice == 'risk_mau':
            # Users at risk monthly, with the last engagement between 8 and 30 days ago
            max_date = start_date - timedelta(days=random.randint(8, 30))
            previous_date = max_date - timedelta(days=random.randint(1, 10))
            events_data.extend([(user_id, max_date), (user_id, previous_date)])
        elif bucket_choice == 'dormant':
            # Dormant users with no engagement in the last 30+ days
            max_date = start_date - timedelta(days=random.randint(31, 60))
            previous_date = max_date - timedelta(days=random.randint(1, 10))
            events_data.extend([(user_id, max_date), (user_id, previous_date)])

# Assign users to buckets
assign_to_buckets(user_ids, START_DATE, END_DATE)

# Specify the file name for the CSV output
csv_file_name = 'events_data.csv'

# Write the data to a CSV file
with open(csv_file_name, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['user_id', 'date_created'])  # Writing the header
    writer.writerows(events_data)  # Writing the data rows

print(f"Data successfully written to {csv_file_name}")