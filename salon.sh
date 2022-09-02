#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ Salon Appointment Scheduler ~~~~~\n"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo "How may I help you?" 
  echo -e "\n1. New Appointment \n2. Cancel Appointment \n3. Exit"
  read MAIN_MENU_SELECTION

  case $MAIN_MENU_SELECTION in
    1) NEW_APPOINTMENT ;;
    2) CANCEL_APPOINTMENT ;;
    3) EXIT ;;
    *) MAIN_MENU "Please enter a valid option." ;;
  esac
}

NEW_APPOINTMENT(){
  echo -e "\n~~~~~ New Appointment ~~~~~"
  #get available services
  AVAILABLE_SERVICES=$($PSQL "select service_id, INITCAP(name) as name from services;")
  
  # if no available services
  if [[ -z $AVAILABLE_SERVICES ]]
  then
    # send to main menu
    MAIN_MENU "Sorry, we don't have any services available right now."
  else
    # display available services
    echo -e "\nHere are the services we offer:"
    echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
    do
      echo "$SERVICE_ID) $NAME."
    done

  #ask for input service
  echo -e "\nWhich one would you like to choose?"
  read SERVICE_ID_SELECTED

  #check if input service is numbers
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    # send to main menu
    NEW_APPOINTMENT "That is not a valid service."
  else
    # get bike availability
    SERVICE_EXISTS=$($PSQL "select name from services where service_id=$SERVICE_ID_SELECTED")
    
    #if service does not exist, return to main menu
    if [[ -z $SERVICE_EXISTS ]] 
    then
      NEW_APPOINTMENT "That service does not exist."
    else
      #if service exists ask for phone
      echo -e "\nPlease enter your phone number in order to continue:"
      read CUSTOMER_PHONE

      #check if customer exists
      CUSTOMER_NAME=$($PSQL "select name from customers where phone='$CUSTOMER_PHONE'")

      #if phone number does not exist, create customer
      if [[ -z $CUSTOMER_NAME ]]
      then
        #get customers name
        echo -e "\nIt seems it's the first time you are booking with us, please enter your name:"
        read CUSTOMER_NAME

        # insert new customer
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')") 
      fi

      # get customer_id
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

      #get appointment time
      echo -e "\nPlease enter the time you'd like to get your $SERVICE_EXISTS done:"
      read SERVICE_TIME

      # insert appointment
      INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED,'$SERVICE_TIME')")

      #check if appoint was created successfully
      if [[ -z $INSERT_APPOINTMENT_RESULT ]]
      then
        # send to main menu
        MAIN_MENU "We are sorry, it seems that there was an error processing your request. Please try again."
      else
        # send to main menu
        MAIN_MENU "I have put you down for a $SERVICE_EXISTS at $SERVICE_TIME, $CUSTOMER_NAME."
      fi
    fi
  fi
fi
}

CANCEL_APPOINTMENT(){
  echo Cancel Appointment
}

EXIT(){
  echo -e "\nThank you for stopping in.\n"
}

MAIN_MENU