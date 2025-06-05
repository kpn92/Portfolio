import pandas as pd
import matplotlib.pyplot as plt

# Load the sample dataset
sample_file_path = '10-employees.csv'
sample_df = pd.read_csv(r'C:\WorkEarlyDataAnalysis\Employee Data Analysis\10-employees.csv')

# Group by department and calculate the average salary and employee satisfaction
dept_analysis = sample_df.groupby('Department').agg({
    'Salary': 'mean',
    'EmpSatisfaction': 'mean'
}).reset_index() # Μετατρέπει το αποτέλεσμα από groupby object σε κανονικό DataFrame με αριθμητικό index.

# Plotting the results
fig, ax1 = plt.subplots(figsize=(12, 8))

# Bar chart for average salary
ax1.bar(dept_analysis['Department'], dept_analysis['Salary'], color='b', alpha=0.6, label='Average Salary')
ax1.set_xlabel('Department')
ax1.set_ylabel('Average Salary', color='b')
ax1.tick_params(axis='y', labelcolor='b')

# Creating a second y-axis for average employee satisfaction
ax2 = ax1.twinx()
ax2.plot(dept_analysis['Department'], dept_analysis['EmpSatisfaction'], color='r', marker='o', label='Average Employee Satisfaction')
ax2.set_ylabel('Average Employee Satisfaction', color='r')
ax2.tick_params(axis='y', labelcolor='r')

# Adding titles and legends
plt.title('Average Salary and Employee Satisfaction by Department')
fig.tight_layout()
ax1.legend(loc='upper left')
ax2.legend(loc='upper right')

# Show plot
plt.show()
