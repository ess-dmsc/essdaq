import pandas as pd
import matplotlib.pyplot as plt

# Path to the CSV file
csv_file_path = 'output.csv'

# Read the CSV file into a pandas DataFrame
data = pd.read_csv(csv_file_path)

# Extract AmplA and AmplB columns
ampl_a = data['AmplA']
ampl_b = data['AmplB']

# Create a scatter plot
plt.scatter(ampl_a, ampl_b, s=1)

# Add labels and title
plt.xlabel('AmplA')
plt.ylabel('AmplB')
plt.title('Scatter plot of AmplA vs AmplB')

# Save the plot to a PNG file
plt.savefig('scatter_plot.png')

# Show the plot
plt.show()