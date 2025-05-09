Okay, let's get your Red Hat Satellite 6.11 configured for automated patching of your Linux servers. Here's a step-by-step guide to set up this automation:

**Phase 1: Content Management and Views**

1.  **Ensure Relevant Content is Available:**
    * Verify that you have the necessary Red Hat Enterprise Linux repositories enabled and synchronized in your Satellite server for the operating system versions you want to patch. Navigate to **Content** > **Subscriptions** or **Content** > **Red Hat Repositories**.
    * Ensure these repositories are part of a **Content View**.

2.  **Create or Modify a Content View for Patches:**
    * Navigate to **Content** > **Content Views**.
    * You can either create a new Content View specifically for patches or modify an existing one.
    * If creating a new one, click **Create New Content View**, give it a name (e.g., `RHEL7-Patches`), and a description.
    * Click on the Content View name.
    * Go to the **Repositories** tab and add the relevant update repositories for your target systems (e.g., `Red Hat Enterprise Linux 7 Server - Updates (RPMs)`).
    * **Publish a New Version** of your Content View after adding the repositories. Promote this new version through your lifecycle environments (e.g., Library -> Test -> Production) as needed.

**Phase 2: Defining Patching Policies**

1.  **Navigate to Patch Policies:**
    * Go to **Configure** > **Patch Policies**.

2.  **Create a New Patch Policy:**
    * Click **New Patch Policy**.
    * **Name:** Give your policy a descriptive name (e.g., `Weekly Security Patches - RHEL7`).
    * **Description:** Add a brief explanation of the policy's purpose.
    * **Content View:** Select the Content View you created or modified in Phase 1 that contains the update repositories.
    * **Lifecycle Environment:** Choose the lifecycle environment where the policy will be applied (e.g., Production).
    * **Schedule:** Define the schedule for when the patching should occur. You can set the frequency (Daily, Weekly, Monthly), the day(s) of the week/month, and the time.
    * **Package Group:** This is a crucial setting. You can choose to install:
        * **All Installable Packages:** Installs all available updates. Use with caution in production environments.
        * **Security Advisory:** Installs only packages related to security advisories. This is generally the recommended approach for automated patching.
        * **Bugfix Advisory:** Installs only packages related to bugfix advisories.
        * **Enhancement Advisory:** Installs only packages related to enhancement advisories.
        * **Selected Packages:** Allows you to specify individual packages to include or exclude. This is less suitable for broad automation.
    * **Content Type:** Typically set to `rpm`.
    * **Host Collection Type:** Choose how to select the hosts that will be affected by this policy:
        * **Host Group:** Apply the policy to a specific Host Group (recommended for organized management).
        * **All Hosts:** Apply the policy to all managed hosts in the selected lifecycle environment. Use with extreme caution.
        * **Operating System:** Apply the policy to hosts with a specific operating system.
        * **Content Host Group:** Apply the policy to a Content Host Group.
    * **Host Collections:** Based on your selection above, choose the specific Host Group(s), operating system(s), or all hosts.
    * **Run at:** Specify the time of day the patching should start on the scheduled days.
    * **Time Zone:** Select the appropriate time zone for the schedule.
    * **Email Notification:** Optionally configure email notifications to be sent upon the success or failure of the patch application.

3.  **Save the Patch Policy:**
    * Click **Submit** to save your new patch policy.

**Phase 3: Applying Patch Policies to Hosts/Host Groups**

1.  **Assign Policies to Host Groups (Recommended):**
    * Navigate to **Hosts** > **Host Groups**.
    * Select the Host Group(s) you want to apply the patch policy to.
    * Go to the **Patch Policies** tab.
    * Click **Add**.
    * Select the patch policy you created and click **Add Selected**.

2.  **Alternatively, Assign Policies to Individual Hosts:**
    * Navigate to **Hosts** > **All Hosts**.
    * Select the host(s) you want to apply the patch policy to.
    * Go to the **Patch Policies** tab.
    * Click **Add**.
    * Select the patch policy and click **Add Selected**.

**Phase 4: Enabling and Managing Automatic Actions**

1.  **Configure Automatic Actions:**
    * Go to **Administer** > **Settings** > **Tasks**.
    * Look for the following settings and ensure they are configured as desired:
        * **Apply Patch Policy:** This setting determines if the patch policy should be automatically applied when the scheduled time arrives. Set this to **Yes** to enable automatic patching.
        * **Apply Patch Policy - Start at:** This setting defines the default start time for applying patch policies if not specified in the policy itself.
        * **Apply Patch Policy - Run interval:** This setting defines how often Satellite checks for patch policies that need to be applied. The default is usually sufficient.

2.  **Review and Adjust Task Settings (Optional):**
    * Explore other task-related settings under **Administer** > **Settings** > **Tasks** to fine-tune how tasks are handled, such as maximum concurrent tasks, task retention, etc.

**Phase 5: Monitoring and Reporting**

1.  **Monitor Patch Policy Runs:**
    * Navigate to **Monitor** > **Tasks**.
    * You can filter tasks by "Apply Patch Policy" to see the status of scheduled patching runs.
    * Check the task details for any errors or failures.

2.  **Review Host Patching Status:**
    * Go to **Hosts** > **All Hosts**.
    * Select a host and go to the **Patches** tab to see the installed and applicable patches.
    * You can also generate reports on patch compliance across your managed hosts under **Reports**.

**Important Considerations and Best Practices:**

* **Testing in Non-Production:** Always thoroughly test your patch policies in non-production environments (e.g., Development, Test) before applying them to production servers.
* **Security Advisories Focus:** For automated patching, focusing on **Security Advisory** updates is generally the safest approach to minimize the risk of introducing instability.
* **Maintenance Windows:** Schedule your patch policies to run during designated maintenance windows to minimize potential disruption.
* **Host Group Organization:** Organize your servers into logical Host Groups based on their function and required patching levels. This allows for more granular control over patch policies.
* **Content View Promotion:** Carefully manage the promotion of your patch-related Content Views through your lifecycle environments to ensure that only tested and approved patches reach your production systems.
* **Rollback Strategy:** Have a rollback plan in case an automated patch introduces issues. Satellite provides tools for managing package versions, and you can potentially revert to previous states if necessary.
* **Notifications:** Configure email notifications to stay informed about the success or failure of patching runs.
* **Regular Review:** Periodically review your patch policies and adjust them as needed based on your environment and security requirements.

By following these steps, you can effectively set up automated patching for your Linux servers managed by Red Hat Satellite 6.11, improving the security and stability of your environment. Remember to tailor the policies and schedules to your specific needs and always prioritize testing.
