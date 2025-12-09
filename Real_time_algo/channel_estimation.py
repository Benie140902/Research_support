import socket
import numpy as np
from collections import deque

UDP_IP = "127.0.0.1"
UDP_PORT = 5005

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

# parameters
M = 100
delay_buf = deque(maxlen=M)
Fs = 46.08e6
Ts = 1.0 / Fs   
sigma2 = 1e-3   

while True:
    data, addr = sock.recvfrom(65536)
    arr = np.frombuffer(data, dtype=np.float32)

    try:
        rows = arr.reshape(-1, 7)  
    except Exception as e:

        continue

    rx = rows[:, 1] + 1j * rows[:, 2]   # received complex symbols
    tx = rows[:, 3] + 1j * rows[:, 4]   # transmitted complex symbols
    est_lse = rows[:, 5] + 1j * rows[:, 6]  # sender-provided LSE (if that's what it is)

   
    nonzero_mask = np.abs(tx) > 1e-12
    if not np.any(nonzero_mask):
     
        continue
    h_true = np.zeros_like(rx, dtype=np.complex128)
    h_true[nonzero_mask] = rx[nonzero_mask] / tx[nonzero_mask]
    h_true[~nonzero_mask] = np.nan

    h_ls = h_true.copy()  
    
    # Compute MMSE 
    h_mmse_per_symbol = np.zeros_like(h_ls, dtype=np.complex128)
    h_mmse_per_symbol[nonzero_mask] = (rx[nonzero_mask] * np.conj(tx[nonzero_mask])) / \
                                      (np.abs(tx[nonzero_mask])**2 + sigma2)
    N = np.sum(nonzero_mask)
    num = np.sum(rx[nonzero_mask] * np.conj(tx[nonzero_mask]))
    den = np.sum(np.abs(tx[nonzero_mask])**2) + N * sigma2
    h_mmse_block = num / den
    valid = nonzero_mask
    mse_lse_per_symbol = np.mean(np.abs(h_ls[valid] - h_true[valid])**2)   # this is zero since h_ls==h_true
    
    # Compare two different algorithms
    if est_lse.shape == h_ls.shape:
        mse_est_lse_vs_true = np.mean(np.abs(est_lse[valid] - h_true[valid])**2)
    else:
        mse_est_lse_vs_true = np.nan

    mse_mmse_per_symbol = np.mean(np.abs(h_mmse_per_symbol[valid] - h_true[valid])**2)
    mse_mmse_block = np.mean(np.abs(h_mmse_block - h_true[valid])**2)
    

    print("mse_est_lse_vs_true:", mse_est_lse_vs_true)
    print("mse_mmse_per_symbol:", mse_mmse_per_symbol)
    print("mse_mmse_block:", mse_mmse_block)
    if not np.isnan(mse_est_lse_vs_true):
        if mse_mmse_per_symbol < mse_est_lse_vs_true:
            print("Per-symbol MMSE better than sender LSE (lower MSE).")
        else:
            print("Sender LSE better than per-symbol MMSE.")
    else:
        print("Sender LSE not same shape as computed symbols; cannot compare directly.")

    
    
  
    
    
    
    
