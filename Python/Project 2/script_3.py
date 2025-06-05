import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Load the sample dataset
sample_file_path = '10-employees.csv'
sample_df = pd.read_csv(r'C:\10-employees.csv')

# Analyzing the distribution of employees across different departments
dept_distribution = sample_df['Department'].value_counts()

# Salary statistics within each department
salary_stats = sample_df.groupby('Department')['Salary'].describe()

# Display the salary statistics
print(salary_stats)

# Plotting the pie chart for department distribution
plt.figure(figsize=(10, 8))
plt.pie(dept_distribution, labels=dept_distribution.index, autopct='%1.1f%%', startangle=140, colors=plt.cm.viridis(np.linspace(0, 1, len(dept_distribution))))

# Adding titles
plt.title('Employee Distribution by Department')

# Show plot
plt.show()
